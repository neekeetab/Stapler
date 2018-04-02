import UIKit
import ReactiveSwift
import ReactiveCocoa
import Stapler

extension Reactive where Base: UITableView {
    
    // Binding target for UITableView's tableFooterView property
    var tableFooterView: BindingTarget<UIView?> {
        return makeBindingTarget { tableView, view in
            tableView.tableFooterView = view
        }
    }
    
}

class ViewWithActivityIndicatorInIt: UIView {
    
    let activityIndicatorView: UIActivityIndicatorView
    
    override init(frame: CGRect) {
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: frame)
        self.addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()
        activityIndicatorView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
    
}

class ViewController: UIViewController {
    
    let viewModel = ViewModel()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var initialLoadActivityIndicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup refresh control
        let refreshControl = UIRefreshControl()
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        refreshControl.reactive.refresh = CocoaAction(viewModel.stapler.refreshAction)
        
        // setup activity indicator at the bottom
        let activityIndicatorHolder = ViewWithActivityIndicatorInIt(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 60))
        let dummyViewToHideSeparatorsAtTheBottom = UIView()
        tableView.reactive.tableFooterView <~ viewModel.stapler.shouldShowNextPageActivityIndicator
            .map { $0 ? activityIndicatorHolder : dummyViewToHideSeparatorsAtTheBottom }
        
        // reload table view on each change in data source
        tableView.reactive.reloadData <~ viewModel.stapler.items.map { _ in () }
        
        // hide initialLoadActivityIndicatorView after the initial load
        initialLoadActivityIndicatorView.reactive.isHidden <~ viewModel.stapler.initialLoadAction.isExecuting.negate()
        
        // start loading
        viewModel.stapler.initialLoadAction.apply().start()
        
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.stapler.items.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = viewModel.stapler.items.value[indexPath.row].value
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == viewModel.stapler.items.value.count - 1 {
            viewModel.stapler.loadNextPageIfNeeded()
        }
    }
    
}
