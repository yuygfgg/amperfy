import UIKit
import CoreData

class ArtistDetailVC: BasicTableViewController {

    var artist: Artist!
    private var albumsFetchedResultsController: ArtistAlbumsItemsFetchedResultsController!
    private var songsFetchedResultsController: ArtistSongsItemsFetchedResultsController!
    private var detailOperationsView: ArtistDetailTableHeader?

    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate.userStatistics.visited(.artistDetail)
        
        albumsFetchedResultsController = ArtistAlbumsItemsFetchedResultsController(for: artist, managedObjectContext: appDelegate.persistentStorage.context, isGroupedInAlphabeticSections: false)
        albumsFetchedResultsController.delegate = self
        songsFetchedResultsController = ArtistSongsItemsFetchedResultsController(for: artist, managedObjectContext: appDelegate.persistentStorage.context, isGroupedInAlphabeticSections: false)
        songsFetchedResultsController.delegate = self
        tableView.register(nibName: AlbumTableCell.typeName)
        tableView.register(nibName: SongTableCell.typeName)
        
        configureSearchController(placeholder: "Albums and Songs", scopeButtonTitles: ["All", "Cached"])
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: ArtistDetailTableHeader.frameHeight + LibraryElementDetailTableHeaderView.frameHeight))
        if let artistDetailTableHeaderView = ViewBuilder<ArtistDetailTableHeader>.createFromNib(withinFixedFrame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: ArtistDetailTableHeader.frameHeight)) {
            artistDetailTableHeaderView.prepare(toWorkOnArtist: artist, rootView: self)
            tableView.tableHeaderView?.addSubview(artistDetailTableHeaderView)
            detailOperationsView = artistDetailTableHeaderView
        }
        if let libraryElementDetailTableHeaderView = ViewBuilder<LibraryElementDetailTableHeaderView>.createFromNib(withinFixedFrame: CGRect(x: 0, y: ArtistDetailTableHeader.frameHeight, width: view.bounds.size.width, height: LibraryElementDetailTableHeaderView.frameHeight)) {
            libraryElementDetailTableHeaderView.prepare(
                playContextCb: {() in PlayContext(playables: self.songsFetchedResultsController.getContextSongs(onlyCachedSongs: self.appDelegate.persistentStorage.settings.isOfflineMode) ?? [])},
                with: appDelegate.player)
            tableView.tableHeaderView?.addSubview(libraryElementDetailTableHeaderView)
        }
        
        swipeCallback = { (indexPath, completionHandler) in
            switch indexPath.section+2 {
            case LibraryElement.Album.rawValue:
                let album = self.albumsFetchedResultsController.getWrappedEntity(at: IndexPath(row: indexPath.row, section: 0))
                self.fetchDetails(of: album) {
                    completionHandler(album.playables)
                }
            case LibraryElement.Song.rawValue:
                let song = self.songsFetchedResultsController.getWrappedEntity(at: IndexPath(row: indexPath.row, section: 0))
                completionHandler([song])
            default:
                completionHandler([])
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchDetails(of: artist) {
            self.detailOperationsView?.refresh()
        }
    }

    func convertCellViewToPlayContext(cell: UITableViewCell) -> PlayContext? {
        guard let indexPath = tableView.indexPath(for: cell),
              indexPath.section+2 == LibraryElement.Song.rawValue,
              let songs = self.songsFetchedResultsController.getContextSongs(onlyCachedSongs: self.appDelegate.persistentStorage.settings.isOfflineMode)
        else { return nil }
        let selectedSong = self.songsFetchedResultsController.getWrappedEntity(at: IndexPath(row: indexPath.row, section: 0))
        guard let playContextIndex = songs.firstIndex(of: selectedSong) else { return nil }
        return PlayContext(index: playContextIndex, playables: songs)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section+2 {
        case LibraryElement.Album.rawValue:
            return "Albums"
        case LibraryElement.Song.rawValue:
            return "Songs"
        default:
            return ""
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section+2 {
        case LibraryElement.Album.rawValue:
            return albumsFetchedResultsController.sections?[0].numberOfObjects ?? 0
        case LibraryElement.Song.rawValue:
            return songsFetchedResultsController.sections?[0].numberOfObjects ?? 0
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section+2 {
        case LibraryElement.Album.rawValue:
            let cell: AlbumTableCell = dequeueCell(for: tableView, at: indexPath)
            let album = albumsFetchedResultsController.getWrappedEntity(at: IndexPath(row: indexPath.row, section: 0))
            cell.display(album: album, rootView: self)
            return cell
        case LibraryElement.Song.rawValue:
            let cell: SongTableCell = dequeueCell(for: tableView, at: indexPath)
            let song = songsFetchedResultsController.getWrappedEntity(at: IndexPath(row: indexPath.row, section: 0))
            cell.display(song: song, playContextCb: self.convertCellViewToPlayContext, rootView: self)
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section+2 {
        case LibraryElement.Album.rawValue:
            return albumsFetchedResultsController.sections?[0].numberOfObjects ?? 0 > 0 ? CommonScreenOperations.tableSectionHeightLarge : 0
        case LibraryElement.Song.rawValue:
            return songsFetchedResultsController.sections?[0].numberOfObjects ?? 0 > 0 ? CommonScreenOperations.tableSectionHeightLarge : 0
        default:
            return 0.0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section+2 {
        case LibraryElement.Album.rawValue:
            return AlbumTableCell.rowHeight
        case LibraryElement.Song.rawValue:
            return SongTableCell.rowHeight
        default:
            return 0.0
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section+2 {
        case LibraryElement.Album.rawValue:
            let album = albumsFetchedResultsController.getWrappedEntity(at: IndexPath(row: indexPath.row, section: 0))
            performSegue(withIdentifier: Segues.toAlbumDetail.rawValue, sender: album)
        case LibraryElement.Song.rawValue: break
        default: break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.toAlbumDetail.rawValue {
            let vc = segue.destination as! AlbumDetailVC
            let album = sender as? Album
            vc.album = album
        }
    }
    
    override func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        if searchText.count > 0, searchController.searchBar.selectedScopeButtonIndex == 0 {
            albumsFetchedResultsController.search(searchText: searchText, onlyCached: false)
            songsFetchedResultsController.search(searchText: searchText, onlyCachedSongs: false)
        } else if searchController.searchBar.selectedScopeButtonIndex == 1 {
            albumsFetchedResultsController.search(searchText: searchText, onlyCached: true)
            songsFetchedResultsController.search(searchText: searchText, onlyCachedSongs: true)
        } else {
            albumsFetchedResultsController.showAllResults()
            songsFetchedResultsController.showAllResults()
        }
        tableView.reloadData()
    }
    
    override func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        var section: Int = 0
        switch controller {
        case albumsFetchedResultsController.fetchResultsController:
            section = LibraryElement.Album.rawValue - 2
        case songsFetchedResultsController.fetchResultsController:
            section = LibraryElement.Song.rawValue - 2
        default:
            return
        }
        
        super.applyChangesOfMultiRowType(determinedSection: section, at: indexPath, for: type, newIndexPath: newIndexPath)
    }
    
    override func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    }
    
}
