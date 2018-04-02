import Foundation
import Stapler

class ViewModel {
    
    let stapler = Stapler(pageSize: 5) { offset, size in
        // provide network request for given offset and size
        NetworkService.items(offset: offset, size: size)
    }
    
}
