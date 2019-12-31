import Foundation
import CoreData
import UIKit

public class Song: AbstractLibraryElement {
    
    let managedObject: SongMO
    
    init(managedObject: SongMO) {
        self.managedObject = managedObject
        super.init(managedObject: managedObject)
    }
    
    var objectID: NSManagedObjectID {
        return managedObject.objectID
    }
     var title: String {
         get { return managedObject.title ?? "Unknown title" }
         set { managedObject.title = newValue }
     }
     var track: Int {
         get { return Int(managedObject.track) }
         set { managedObject.track = Int16(newValue) }
     }
     var url: String? {
         get { return managedObject.url }
         set { managedObject.url = newValue }
     }
     var album: Album? {
         get { return managedObject.album }
         set { managedObject.album = newValue }
     }
     var artist: Artist? {
         get { return managedObject.artist }
         set { managedObject.artist = newValue }
     }
     //TODO: use SongData instead of MO
     var fileDataContainer: SongDataMO? {
         get { return managedObject.fileDataContainer }
         set { managedObject.fileDataContainer = newValue }
     }
     var fileData: NSData? {
         return managedObject.fileDataContainer?.data
     }
     //TODO: use SongData instead of MO
     var syncInfo: SyncWaveMO? {
         get { return managedObject.syncInfo }
         set { managedObject.syncInfo = newValue }
    }
    
    var displayString: String {
        return "\(managedObject.artist?.name ?? "Unknown artist") - \(title)"
    }
    
    override var identifier: String {
        return title
    }

    override var image: UIImage {
        if let curAlbum = managedObject.album, !curAlbum.isOrphaned {
            if super.image != Artwork.defaultImage {
                return super.image
            }
        }
        if let artistArt = managedObject.artist?.artwork?.image {
            return artistArt
        }
        return Artwork.defaultImage
    }

    var isCached: Bool {
        if let _ = managedObject.fileDataContainer?.data {
            return true
        }
        return false
    }
    
}

extension Array where Element: Song {
    
    func filterCached() -> [Element] {
        let filteredArray = self.filter { element in
            return element.isCached
        }
        return filteredArray
    }
    
    func filterCustomArt() -> [Element] {
        let filteredArray = self.filter{ element in
            return element.image != Artwork.defaultImage
        }
        return filteredArray
    }
    
    var hasCachedSongs: Bool {
        for song in self {
            if song.isCached {
                return true
            }
        }
        return false
    }
    
}