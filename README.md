<p align="center">
	<img src="Resources/Stapler.png" alt="Stapler" height="100" />
</p>
</br>

**Stapler** is a Swift micro framework for iOS that **encapsulates all the logic for fetching and refreshing paginated data**. **Stapler** performs necessary backend requests and provides you with a ready-to-bind-to-UI reactive data source. 

No more reinventing the wheel – **Stapler** will save you a ton of time next time you need to display paginated data in your collection view. 

Note, that **Stapler** relies heavily on [ReactiveSwift][]. Also, you will most likely want to use [ReactiveCocoa][] for easy UI bindings. You're supposed to be familiar with both of these frameworks, albeit you can use your own reactive extensions instead of (or along with) ReactiveCocoa.


[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat-square)](#carthage) [![CocoaPods compatible](https://img.shields.io/cocoapods/v/Stapler.svg?style=flat-square)](#cocoapods) ![GitHub release](https://img.shields.io/github/release/neekeetab/Stapler.svg?style=flat-square) ![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat-square) ![platforms](https://img.shields.io/badge/iOS-8.0+-lightgrey.svg?style=flat-square)

## Installation

#### Carthage

If you use [Carthage][] to manage your dependencies, simply add
**Stapler** to your `Cartfile`:

```
github "neekeetab/Stapler" ~> 0.2
```

If you use Carthage to build your dependencies, make sure you have added `Stapler.framework`, `ReactiveSwift.framework`, `ReactiveCocoa.framework` and `Result.framework` to the "_Linked Frameworks and Libraries_" section of your target, and have them included in your Carthage framework copying build phase.

#### CocoaPods

If you use [CocoaPods][] to manage your dependencies, simply add
**Stapler** to your `Podfile`:

```
pod 'Stapler', '~> 0.2'
```

#### Git submodule

 1. Add the **Stapler** repository as a [submodule][] of your application’s repository.
 1. Run `git submodule update --init --recursive` from within the ```Stapler``` folder.
 1. Drag and drop `Stapler.xcodeproj`, `Carthage/Checkouts/Result/Result.xcodeproj`, `Carthage/Checkouts/ReactiveSwift/ReactiveSwift.xcodeproj`, and `Carthage/Checkouts/ReactiveCocoa/ReactiveCocoa.xcodeproj` into your application’s Xcode project or workspace.
 1. On the “General” tab of your application target’s settings, add `Stapler.framework`, `ReactiveSwift.framework`, `ReactiveCocoa.framework` and `Result.framework` to the “Embedded Binaries” section.
 1. If your application target does not contain Swift code at all, you should also set the `EMBEDDED_CONTENT_CONTAINS_SWIFT` build setting to “Yes”.


## Usage

Stapler makes pagination handling easy. Here's how to use it: 

#### 1. `PaginatedResponse` Protocol

Conform your paginated server response to the ```PaginatedResponse``` protocol.

```Swift
/**
 Protocol to conform data structures representing paginated server responses to.
 */
public protocol PaginatedResponse {
    associatedtype Item
    var items: [Item] { get }
    var total: UInt { get }
}
```

#### 2. View Model

In a view model (or somewhere else if you don't follow MVVM), initialize ```Stapler```, providing a `SignalProducer` that represents the network request.

```Swift
/* Suppose we have this declared somewhere in the project
class NetworkService {

	//...

	struct ItemsResponse: PaginatedResponse {
		let total: UInt
		let items: Item
	}
	
	/// Sends ItemsResponse and completes on success, Error otherwise. 
	static func items(offset: UInt, size: UInt) -> SignalProducer<ItemsResponse, Error>
	
}
*/

class ViewModel {

	let stapler = Stapler(pageSize: 10) { offset, size in
		// return network request with PaginatedResponse as a value type
		NetworkService.items(offset: offset, size: size)
	}

}
```

Have you noticed? It's only **3 lines of code** :bowtie: for a view model!

#### 3. View

All that is left now is to bind ```stapler``` from the view model to your view, usually containing one of the ```UICollectionView``` subclasses. You can find an example of how to do it in the [demo project](#demo-project) section.

### Public interface

```Stapler``` aggregates everything needed to bind your UI to. Here's what you get:

```Swift
/**
 Contains all the logic for fetching and refreshing paginated data. Provides
 reactive data source to bind your UI to. Standardizes the process of getting
 paginated content and (arguably) makes your life (a little bit) easier.
 */
open class Stapler<Response: PaginatedResponse, ResponseError: Error> {
    
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
    public func loadNextPageIfNeeded() 
    
    /**
     - parameters:
         - pageSize: Number of elements per page.
         - request: A closure to provide request to your backend for given offset
            and size.
     */
    public init(pageSize: UInt,
         request: @escaping (_ offset: UInt, _ size: UInt) -> SignalProducer<Response, ResponseError>) 
    
}

```

## <a name="demo-project"></a>Demo project

<p align="center">
	<img src="Resources/Demo.gif" width=320>
</p>
</br>

To get a better understanding of how **Stapler** works, take a look at the demo project. Here's how to run it:

 1. Clone the **Stapler** repository.
 1. Retrieve the project dependencies using one of the following terminal commands from the **Stapler** project root directory:
     - `git submodule update --init --recursive` **OR**, if you have [Carthage][] installed    
     - `carthage checkout`
 1. Open `Stapler.xcworkspace`
 1. Build `Result-iOS` scheme
 1. Build `ReactiveSwift-iOS` scheme
 1. Build `ReactiveCocoa-iOS` scheme
 1. Build `Stapler` scheme
 1. Run `StaplerDemo` target 

## Limitations
In its current implementation, **Stapler** supports offset-based pagination only. Thus, there are two requirements for your backend:

- requests must take **offset** and **page size** as parameters
- each response must contain **tottal number of elements**

## Is there something missing?
Feel free to request it!

## Have a question?
Feel free to create a github issue!

[ReactiveSwift]: https://github.com/ReactiveCocoa/ReactiveSwift/#readme
[ReactiveCocoa]: https://github.com/ReactiveCocoa/ReactiveCocoa/#readme
[Carthage]: https://github.com/Carthage/Carthage/#readme
[CocoaPods]: https://cocoapods.org/
[submodule]: https://git-scm.com/docs/git-submodule
