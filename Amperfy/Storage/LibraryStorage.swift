import Foundation
import CoreData
import os.log

protocol SongFileCachable {
    func getSongFile(forSong song: Song) -> SongFile?
}

enum PlaylistSearchCategory: Int {
    case all = 0
    case userOnly = 1
    case smartOnly = 2

    static let defaultValue: PlaylistSearchCategory = .all
}

class LibraryStorage: SongFileCachable {
    
    static let entitiesToDelete = [Genre.typeName, Artist.typeName, Album.typeName, Song.typeName, SongFile.typeName, Artwork.typeName, SyncWave.typeName, Playlist.typeName, PlaylistItem.typeName, PlayerData.entityName, LogEntry.typeName, MusicFolder.typeName, Directory.typeName]

    private let log = OSLog(subsystem: AppDelegate.name, category: "LibraryStorage")
    private var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func getInfo() -> LibraryInfo {
        var libraryInfo = LibraryInfo()
        libraryInfo.artistCount = artistCount
        libraryInfo.albumCount = albumCount
        libraryInfo.songCount = songCount
        libraryInfo.cachedSongCount = cachedSongCount
        libraryInfo.playlistCount = playlistCount
        libraryInfo.cachedSongSize = cachedSongSizeInByte.asByteString
        libraryInfo.genreCount = genreCount
        libraryInfo.syncWaveCount = syncWaveCount
        libraryInfo.artworkCount = artworkCount
        libraryInfo.musicFolderCount = musicFolderCount
        libraryInfo.directoryCount = directoryCount
        return libraryInfo
    }
    
    var genreCount: Int {
        return (try? context.count(for: GenreMO.fetchRequest())) ?? 0
    }
    
    var artistCount: Int {
        return (try? context.count(for: ArtistMO.fetchRequest())) ?? 0
    }
    
    var albumCount: Int {
        return (try? context.count(for: AlbumMO.fetchRequest())) ?? 0
    }
    
    var songCount: Int {
        return (try? context.count(for: SongMO.fetchRequest())) ?? 0
    }
    
    var syncWaveCount: Int {
        return (try? context.count(for: SyncWaveMO.fetchRequest())) ?? 0
    }
    
    var artworkCount: Int {
        return (try? context.count(for: ArtworkMO.fetchRequest())) ?? 0
    }
    
    var musicFolderCount: Int {
        return (try? context.count(for: MusicFolderMO.fetchRequest())) ?? 0
    }
    
    var directoryCount: Int {
        return (try? context.count(for: DirectoryMO.fetchRequest())) ?? 0
    }
    
    var cachedSongCount: Int {
        let request: NSFetchRequest<SongMO> = SongMO.fetchRequest()
        request.predicate = NSPredicate(format: "%K != nil", #keyPath(SongMO.file))
        return (try? context.count(for: request)) ?? 0
    }
    
    var playlistCount: Int {
        let request: NSFetchRequest<PlaylistMO> = PlaylistMO.fetchRequest()
        request.predicate = PlaylistMO.excludeSystemPlaylistsFetchPredicate
        return (try? context.count(for: request)) ?? 0
    }
    
    var cachedSongSizeInByte: Int64 {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: SongFile.typeName)
        fetchRequest.propertiesToFetch = [#keyPath(SongFileMO.data)]
        fetchRequest.resultType = .dictionaryResultType
        let foundSongFiles = (try? context.fetch(fetchRequest)) ?? [NSDictionary]()
        let files = foundSongFiles.compactMap{ $0[#keyPath(SongFileMO.data)] as? NSData }
        let cachedSongSizeInByte: Int64 = files.reduce(0, { $0 + $1.sizeInByte})
        return cachedSongSizeInByte
    }
    
    func createGenre() -> Genre {
        let genreMO = GenreMO(context: context)
        return Genre(managedObject: genreMO)
    }
    
    func createArtist() -> Artist {
        let artistMO = ArtistMO(context: context)
        return Artist(managedObject: artistMO)
    }
    
    func createAlbum() -> Album {
        let albumMO = AlbumMO(context: context)
        return Album(managedObject: albumMO)
    }
    
    func deleteAlbum(album: Album) {
        context.delete(album.managedObject)
    }
    
    func createSong() -> Song {
        let songMO = SongMO(context: context)
        return Song(managedObject: songMO)
    }
    
    func createSongFile() -> SongFile {
        let songFileMO = SongFileMO(context: context)
        return SongFile(managedObject: songFileMO)
    }
    
    func createMusicFolder() -> MusicFolder {
        let musicFolderMO = MusicFolderMO(context: context)
        return MusicFolder(managedObject: musicFolderMO)
    }
    
    func deleteMusicFolder(musicFolder: MusicFolder) {
        context.delete(musicFolder.managedObject)
    }
    
    func createDirectory() -> Directory {
        let directoryMO = DirectoryMO(context: context)
        return Directory(managedObject: directoryMO)
    }
    
    func deleteDirectory(directory: Directory) {
        context.delete(directory.managedObject)
    }
    
    func createLogEntry() -> LogEntry {
        let logEntryMO = LogEntryMO(context: context)
        logEntryMO.creationDate = Date()
        return LogEntry(managedObject: logEntryMO)
    }
    
    private func createUserStatistics(appVersion: String) -> UserStatistics {
        let userStatistics = UserStatisticsMO(context: context)
        userStatistics.creationDate = Date()
        userStatistics.appVersion = appVersion
        return UserStatistics(managedObject: userStatistics, libraryStorage: self)
    }
    
    func deleteSongFile(songFile: SongFile) {
        context.delete(songFile.managedObject)
    }

    func deleteCache(ofSong song: Song) {
        if let songFile = getSongFile(forSong: song) {
            deleteSongFile(songFile: songFile)
            song.managedObject.file = nil
        }
    }

    func deleteCache(ofPlaylist playlist: Playlist) {
        for song in playlist.songs {
            if let songFile = getSongFile(forSong: song) {
                deleteSongFile(songFile: songFile)
                song.managedObject.file = nil
            }
        }
    }
    
    func deleteCache(ofGenre genre: Genre) {
        for song in genre.songs {
            if let songFile = getSongFile(forSong: song) {
                deleteSongFile(songFile: songFile)
                song.managedObject.file = nil
            }
        }
    }
    
    func deleteCache(ofArtist artist: Artist) {
        for song in artist.songs {
            if let songFile = getSongFile(forSong: song) {
                deleteSongFile(songFile: songFile)
                song.managedObject.file = nil
            }
        }
    }
    
    func deleteCache(ofAlbum album: Album) {
        for song in album.songs {
            if let songFile = getSongFile(forSong: song) {
                deleteSongFile(songFile: songFile)
                song.managedObject.file = nil
            }
        }
    }

    func deleteCompleteSongCache() {
        clearStorage(ofType: SongFile.typeName)
    }
    
    func createArtwork() -> Artwork {
        return Artwork(managedObject: ArtworkMO(context: context))
    }
    
    func deleteArtwork(artwork: Artwork) {
        context.delete(artwork.managedObject)
    }
 
    func createPlaylist() -> Playlist {
        return Playlist(storage: self, managedObject: PlaylistMO(context: context))
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        context.delete(playlist.managedObject)
    }
    
    func createPlaylistItem() -> PlaylistItem {
        let itemMO = PlaylistItemMO(context: context)
        return PlaylistItem(storage: self, managedObject: itemMO)
    }
    
    func deletePlaylistItem(item: PlaylistItem) {
        context.delete(item.managedObject)
    }
    
    func deleteSyncWave(item: SyncWave) {
        context.delete(item.managedObject)
    }

    func createSyncWave() -> SyncWave {
        let syncWaveCount = Int16(getSyncWaves().count)
        let syncWaveMO = SyncWaveMO(context: context)
        syncWaveMO.id = syncWaveCount
        return SyncWave(managedObject: syncWaveMO)
    }
    
    func getFetchPredicate(forSyncWave syncWave: SyncWave) -> NSPredicate {
        return NSPredicate(format: "(syncInfo == %@)", syncWave.managedObject.objectID)
    }
    
    func getFetchPredicate(forGenre genre: Genre) -> NSPredicate {
        return NSPredicate(format: "genre == %@", genre.managedObject.objectID)
    }
    
    func getFetchPredicate(forArtist artist: Artist) -> NSPredicate {
        return NSPredicate(format: "artist == %@", artist.managedObject.objectID)
    }
    
    func getFetchPredicate(forAlbum album: Album) -> NSPredicate {
        return NSPredicate(format: "album == %@", album.managedObject.objectID)
    }
    
    func getFetchPredicate(forPlaylist playlist: Playlist) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(PlaylistItemMO.playlist), playlist.managedObject.objectID)
    }
    
    func getFetchPredicate(forMusicFolder musicFolder: MusicFolder) -> NSPredicate {
        return NSPredicate(format: "musicFolder == %@", musicFolder.managedObject.objectID)
    }
    
    func getSongFetchPredicate(forDirectory directory: Directory) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(SongMO.directory), directory.managedObject.objectID)
    }
    
    func getDirectoryFetchPredicate(forDirectory directory: Directory) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(DirectoryMO.parent), directory.managedObject.objectID)
    }
    
    func getFetchPredicate(onlyCachedSongs: Bool) -> NSPredicate {
        if onlyCachedSongs {
            return NSPredicate(format: "%K != nil", #keyPath(SongMO.file))
        } else {
            return NSPredicate.alwaysTrue
        }
    }
    
    func getFetchPredicate(forPlaylistSearchCategory playlistSearchCategory: PlaylistSearchCategory) -> NSPredicate {
        switch playlistSearchCategory {
        case .all:
            return NSPredicate.alwaysTrue
        case .userOnly:
            return NSPredicate(format: "NOT (%K BEGINSWITH %@)", #keyPath(PlaylistMO.id), Playlist.smartPlaylistIdPrefix)
        case .smartOnly:
            return NSPredicate(format: "%K BEGINSWITH %@", #keyPath(PlaylistMO.id), Playlist.smartPlaylistIdPrefix)
        }
    }

    func getArtists() -> [Artist] {
        let fetchRequest = ArtistMO.identifierSortedFetchRequest
        let foundArtists = try? context.fetch(fetchRequest)
        let artists = foundArtists?.compactMap{ Artist(managedObject: $0) }
        return artists ?? [Artist]()
    }
    
    func getAlbums() -> [Album] {
        let fetchRequest = AlbumMO.identifierSortedFetchRequest
        let foundAlbums = try? context.fetch(fetchRequest)
        let albums = foundAlbums?.compactMap{ Album(managedObject: $0) }
        return albums ?? [Album]()
    }

    func getSongs() -> [Song] {
        let fetchRequest = SongMO.identifierSortedFetchRequest
        let foundSongs = try? context.fetch(fetchRequest)
        let songs = foundSongs?.compactMap{ Song(managedObject: $0) }
        return songs ?? [Song]()
    }
    
    func getPlaylists() -> [Playlist] {
        let fetchRequest = PlaylistMO.identifierSortedFetchRequest
        fetchRequest.predicate = PlaylistMO.excludeSystemPlaylistsFetchPredicate
        let foundPlaylists = try? context.fetch(fetchRequest)
        let playlists = foundPlaylists?.compactMap{ Playlist(storage: self, managedObject: $0) }
        return playlists ?? [Playlist]()
    }
    
    func getLogEntries() -> [LogEntry] {
        let fetchRequest: NSFetchRequest<LogEntryMO> = LogEntryMO.creationDateSortedFetchRequest
        let foundEntries = try? context.fetch(fetchRequest)
        let entries = foundEntries?.compactMap{ LogEntry(managedObject: $0) }
        return entries ?? [LogEntry]()
    }
    
    func getPlayerData() -> PlayerData {
        let fetchRequest: NSFetchRequest<PlayerMO> = PlayerMO.fetchRequest()
        var playerData: PlayerData
        var playerMO: PlayerMO

        if let fetchResults: [PlayerMO] = try? context.fetch(fetchRequest) {
            if fetchResults.count == 1 {
                playerMO = fetchResults[0]
            } else if (fetchResults.count == 0) {
                playerMO = PlayerMO(context: context)
                saveContext()
            } else {
                clearStorage(ofType: PlayerData.entityName)
                playerMO = PlayerMO(context: context)
                saveContext()
            }
        } else {
            playerMO = PlayerMO(context: context)
            saveContext()
        }
        
        if playerMO.normalPlaylist == nil {
            playerMO.normalPlaylist = PlaylistMO(context: context)
            saveContext()
        }
        if playerMO.shuffledPlaylist == nil {
            playerMO.shuffledPlaylist = PlaylistMO(context: context)
            saveContext()
        }
        
        let normalPlaylist = Playlist(storage: self, managedObject: playerMO.normalPlaylist!)
        let shuffledPlaylist = Playlist(storage: self, managedObject: playerMO.shuffledPlaylist!)
        
        if shuffledPlaylist.items.count != normalPlaylist.items.count {
            shuffledPlaylist.removeAllSongs()
            shuffledPlaylist.append(songs: normalPlaylist.songs)
            shuffledPlaylist.shuffle()
        }
        
        playerData = PlayerData(storage: self, managedObject: playerMO, normalPlaylist: normalPlaylist, shuffledPlaylist: shuffledPlaylist)
        
        return playerData
    }

    func getGenre(id: String) -> Genre? {
        let fetchRequest: NSFetchRequest<GenreMO> = GenreMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(GenreMO.id), NSString(string: id))
        fetchRequest.fetchLimit = 1
        let genres = try? context.fetch(fetchRequest)
        return genres?.lazy.compactMap{ Genre(managedObject: $0) }.first
    }
    
    func getGenre(name: String) -> Genre? {
        let fetchRequest: NSFetchRequest<GenreMO> = GenreMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(GenreMO.name), NSString(string: name))
        fetchRequest.fetchLimit = 1
        let genres = try? context.fetch(fetchRequest)
        return genres?.lazy.compactMap{ Genre(managedObject: $0) }.first
    }
    
    func getArtist(id: String) -> Artist? {
        let fetchRequest: NSFetchRequest<ArtistMO> = ArtistMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(ArtistMO.id), NSString(string: id))
        fetchRequest.fetchLimit = 1
        let artists = try? context.fetch(fetchRequest)
        return artists?.lazy.compactMap{ Artist(managedObject: $0) }.first
    }
    
    func getAlbum(id: String) -> Album? {
        let fetchRequest: NSFetchRequest<AlbumMO> = AlbumMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(AlbumMO.id), NSString(string: id))
        fetchRequest.fetchLimit = 1
        let albums = try? context.fetch(fetchRequest)
        return albums?.lazy.compactMap{ Album(managedObject: $0) }.first
    }
    
    func getSong(id: String) -> Song? {
        let fetchRequest: NSFetchRequest<SongMO> = SongMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(SongMO.id), NSString(string: id))
        fetchRequest.fetchLimit = 1
        let songs = try? context.fetch(fetchRequest)
        return songs?.lazy.compactMap{ Song(managedObject: $0) }.first
    }
    
    func getSongFile(forSong song: Song) -> SongFile? {
        guard song.isCached else { return nil }
        let fetchRequest: NSFetchRequest<SongFileMO> = SongFileMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(SongFileMO.info.id), NSString(string: song.id))
        fetchRequest.fetchLimit = 1
        let songFiles = try? context.fetch(fetchRequest)
        return songFiles?.lazy.compactMap{ SongFile(managedObject: $0) }.first
    }

    func getPlaylist(id: String) -> Playlist? {
        let fetchRequest: NSFetchRequest<PlaylistMO> = PlaylistMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(PlaylistMO.id), NSString(string: id))
        fetchRequest.fetchLimit = 1
        let playlists = try? context.fetch(fetchRequest)
        return playlists?.lazy.compactMap{ Playlist(storage: self, managedObject: $0) }.first
    }
    
    func getPlaylist(viaPlaylistFromOtherContext: Playlist) -> Playlist? {
        guard let foundManagedPlaylist = context.object(with: viaPlaylistFromOtherContext.managedObject.objectID) as? PlaylistMO else { return nil }
        return Playlist(storage: self, managedObject: foundManagedPlaylist)
    }
    
    func getArtworks() -> [Artwork] {
        let fetchRequest: NSFetchRequest<ArtworkMO> = ArtworkMO.fetchRequest()
        let foundMusicFolders = try? context.fetch(fetchRequest)
        let artworks = foundMusicFolders?.compactMap{ Artwork(managedObject: $0) }
        return artworks ?? [Artwork]()
    }
    
    func getArtwork(remoteInfo: ArtworkRemoteInfo) -> Artwork? {
        let fetchRequest: NSFetchRequest<ArtworkMO> = ArtworkMO.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == %@", #keyPath(ArtworkMO.id), NSString(string: remoteInfo.id)),
            NSPredicate(format: "%K == %@", #keyPath(ArtworkMO.type), NSString(string: remoteInfo.type))
        ])
        fetchRequest.fetchLimit = 1
        let artworks = try? context.fetch(fetchRequest)
        return artworks?.lazy.compactMap{ Artwork(managedObject: $0) }.first
    }
    
    func getArtworksThatAreNotChecked(fetchCount: Int = 10) -> [Artwork] {
        let fetchRequest: NSFetchRequest<ArtworkMO> = ArtworkMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(ArtworkMO.status), NSNumber(integerLiteral: Int(ImageStatus.NotChecked.rawValue)))
        fetchRequest.fetchLimit = fetchCount
        let foundArtworks = try? context.fetch(fetchRequest)
        let artworks = foundArtworks?.compactMap{ Artwork(managedObject: $0) }
        return artworks ?? [Artwork]()
    }

    func getSyncWaves() -> [SyncWave] {
        let fetchRequest: NSFetchRequest<SyncWaveMO> = SyncWaveMO.fetchRequest()
        let foundSyncWaves = try? context.fetch(fetchRequest)
        let syncWaves = foundSyncWaves?.compactMap{ SyncWave(managedObject: $0) }
        return syncWaves ?? [SyncWave]()
    }

    func getLatestSyncWave() -> SyncWave? {
        let fetchRequest: NSFetchRequest<SyncWaveMO> = SyncWaveMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == max(%K)", #keyPath(SyncWaveMO.id), #keyPath(SyncWaveMO.id))
        fetchRequest.fetchLimit = 1
        let syncWaves = try? context.fetch(fetchRequest)
        return syncWaves?.lazy.compactMap{ SyncWave(managedObject: $0) }.first
    }
    
    func getUserStatistics(appVersion: String) -> UserStatistics {
        let fetchRequest: NSFetchRequest<UserStatisticsMO> = UserStatisticsMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(UserStatisticsMO.appVersion), appVersion)
        fetchRequest.fetchLimit = 1
        if let foundUserStatistics = try? context.fetch(fetchRequest).first {
            return UserStatistics(managedObject: foundUserStatistics, libraryStorage: self)
        } else {
            os_log("New UserStatistics for app version %s created", log: log, type: .info, appVersion)
            let createdUserStatistics = createUserStatistics(appVersion: appVersion)
            saveContext()
            return createdUserStatistics
        }
    }
    
    func getAllUserStatistics() -> [UserStatistics] {
        let fetchRequest: NSFetchRequest<UserStatisticsMO> = UserStatisticsMO.fetchRequest()
        let foundUserStatistics = try? context.fetch(fetchRequest)
        let userStatistics = foundUserStatistics?.compactMap{ UserStatistics(managedObject: $0, libraryStorage: self) }
        return userStatistics ?? [UserStatistics]()
    }
    
    func getMusicFolders() -> [MusicFolder] {
        let fetchRequest: NSFetchRequest<MusicFolderMO> = MusicFolderMO.fetchRequest()
        let foundMusicFolders = try? context.fetch(fetchRequest)
        let musicFolders = foundMusicFolders?.compactMap{ MusicFolder(managedObject: $0) }
        return musicFolders ?? [MusicFolder]()
    }
    
    func getMusicFolder(id: String) -> MusicFolder? {
        let fetchRequest: NSFetchRequest<MusicFolderMO> = MusicFolderMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(MusicFolderMO.id), NSString(string: id))
        fetchRequest.fetchLimit = 1
        let musicFolders = try? context.fetch(fetchRequest)
        return musicFolders?.lazy.compactMap{ MusicFolder(managedObject: $0) }.first
    }
    
    func getDirectory(id: String) -> Directory? {
        let fetchRequest: NSFetchRequest<DirectoryMO> = DirectoryMO.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(DirectoryMO.id), NSString(string: id))
        fetchRequest.fetchLimit = 1
        let directories = try? context.fetch(fetchRequest)
        return directories?.lazy.compactMap{ Directory(managedObject: $0) }.first
    }
    
    func cleanStorage() {
        for entityToDelete in LibraryStorage.entitiesToDelete {
            clearStorage(ofType: entityToDelete)
        }
        saveContext()
    }
    
    private func clearStorage(ofType entityToDelete: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityToDelete)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
        } catch let error as NSError {
            os_log("Fetch failed: %s", log: log, type: .error, error.localizedDescription)
        }
    }
    
    func saveContext () {
        if context.hasChanges {
            do {
                context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}
