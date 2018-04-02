import Foundation
import ReactiveSwift
import enum Result.NoError
import Stapler

/// Represents a unit of something that you usually get in paginated
/// server responses
struct Item {
    let value: String
}

/// Mimics a real network service for demo purposes
class NetworkService {
    
    enum Error: Swift.Error {
        case some
    }
    
    struct ItemsResponse: PaginatedResponse {
        let items: [Item]
        let total: UInt
    }
    
    static func items(offset: UInt, size: UInt) -> SignalProducer<ItemsResponse, Error> {
        
        let lyricsToTheBestSongEver = """
            We're no strangers to love
            You know the rules and so do I
            A full commitment's what I'm thinking of
            You wouldn't get this from any other guy
            I just wanna tell you how I'm feeling
            Gotta make you understand
            Never gonna give you up
            Never gonna let you down
            Never gonna run around and desert you
            Never gonna make you cry
            Never gonna say goodbye
            Never gonna tell a lie and hurt you
            We've known each other for so long
            Your heart's been aching but you're too shy to say it
            Inside we both know what's been going on
            We know the game and we're gonna play it
            And if you ask me how I'm feeling
            Don't tell me you're too blind to see
            Never gonna give you up
            Never gonna let you down
            Never gonna run around and desert you
            Never gonna make you cry
            Never gonna say goodbye
            Never gonna…
        """
        
        let lines = lyricsToTheBestSongEver.split(separator: "\n")
        let total = UInt(lines.count)
        let items = Array(offset ..< min(offset + size, total)).map { Item(value: String(lines[Int($0)])) }
        let response = ItemsResponse(items: items, total: total)
        
        return SignalProducer([response])
            // add delay for demo purposes
            .delay(0.5, on: QueueScheduler.main)
    }
    
}
