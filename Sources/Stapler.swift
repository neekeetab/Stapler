import ReactiveSwift
import ReactiveCocoa
import enum Result.NoError

/**
 Protocol to conform data structures representing paginated server responses to.
 */
public protocol PaginatedResponse {
    associatedtype Item
    var items: [Item] { get }
    var total: UInt { get }
}

/**
 Contains all the logic for fetching and refreshing paginated data. Provides
 reactive data source to bind your UI to. Standardizes the process of getting
 paginated content and (arguably) makes your life (a little bit) easier.
 */
open class Stapler<Response: PaginatedResponse, ResponseError: Error> {
    
    // MARK: - Interface
    
    /**
     An action to perform on initial load (usually in viewDidLoad). Is
     convenient in case you need yet another loading indicator for the initial
     loading. If you don't need that, it's safe to start initial load with the
     refresh action below.
     */
    public let initialLoadAction: Action<(), (), ResponseError>
    
    /**
     An action to perform to reload the content. Loads first page only. To load
     the rest call loadNextPageIfNeeded().
     */
    public let refreshAction: Action<(), (), ResponseError>
    
    /**
     Property containing deserialized elements obtained from paginated server
     responses.
     */
    public let items: MutableProperty<[Response.Item]>
    
    /**
     Property containing the number of pages loaded. Initially is 0.
     */
    public let pages: MutableProperty<UInt>
    
    /**
     Property containing the total number of elements on the backend size.
     Initially is 0.
     */
    public let total: MutableProperty<UInt>
    
    /**
     Property that tells you wheather you should show an activity indicator for
     pages being loaded after the first page is loaded. Initially is false.
     Becomes true at the start of 2nd page loading and stays true until all data
     is loaded (no pages left). Note, that you can obtain execution status for
     the first page with startInitialLoadingAction.isRefreshing if it's an
     initial load or refreshAction.isRefreshing if it's a load after
     refreshing.
     */
    public let shouldShowNextPageActivityIndicator: Property<Bool>
    
    /**
     Signal that notifies about errors that appeared
     while loading 2nd page and further. Note, that you can access errors for
     the first page with startInitialLoadingAction.errors if it's an initial
     load or refreshAction.errors if it's a load after refreshing.
     */
    public let errors2ndPageAndLater: Signal<ResponseError, NoError>
    
    /**
     Loads next page if needed. Usually you should call this function when the
     last cell in a collection view becomes visible. It's safe to call
     loadNextPageIfNeeded() many times subsequently – if there's already a page
     being loaded, all of these calls will be ignored. If there are no pages left,
     calling this function will have no effect.
     */
    public func loadNextPageIfNeeded() {
        loadNextPageSignalObserver.send(value: ())
    }
    
    // MARK: - Implementation
    
    private let loadNextPageSignalObserver: Signal<(), NoError>.Observer
    
    /**
     - parameters:
         - pageSize: Number of elements per page.
         - request: A closure to provie request to your backend for given offset
            and size.
     */
    public init(pageSize: UInt,
                request: @escaping (_ offset: UInt, _ size: UInt) -> SignalProducer<Response, ResponseError>) {
        
        let (loadNextPageSignal, loadNextPageSignalObserver) = Signal<(), NoError>.pipe()
        self.loadNextPageSignalObserver = loadNextPageSignalObserver
        
        let items = MutableProperty<[Response.Item]>([])
        let pages = MutableProperty<UInt>(0)
        let total = MutableProperty<UInt>(0)
        
        let initialLoadAction = Action<(), (), ResponseError> {
            return request(0, pageSize)
                .on(value: { response in
                    pages.value = 1
                    items.value = response.items
                    total.value = response.total
                })
                .map { _ in () }
        }
        
        let refreshAction = Action<(), (), ResponseError> {
            return request(0, pageSize)
                .on(value: { response in
                    pages.value = 1
                    items.value = response.items
                    total.value = response.total
                })
                .map { _ in () }
        }
        
        let loadNextPageAction = Action<(), (), ResponseError> {
            guard pages.value * pageSize < total.value else {
                return SignalProducer.empty
            }
            return request(pages.value * pageSize, pageSize)
                .on(value: { response in
                    items.value += response.items
                    total.value = response.total
                    pages.value += 1
                })
                .map { _ in () }
        }
        
        self.shouldShowNextPageActivityIndicator = pages.combineLatest(with: total)
            .map { pages, total in pages * pageSize < total }
        
        self.errors2ndPageAndLater = loadNextPageAction.errors
        self.initialLoadAction = initialLoadAction
        self.refreshAction = refreshAction
        self.items = items
        self.pages = pages
        self.total = total
        
        loadNextPageSignal
            .filter {
                refreshAction.isExecuting.value == false &&
                    loadNextPageAction.isExecuting.value == false &&
                    total.value > pages.value * pageSize
            }
            .on(value: {
                loadNextPageAction.apply().start()
            })
            .take(duringLifetimeOf: self)
            .observeCompleted { }
        
    }
    
}
