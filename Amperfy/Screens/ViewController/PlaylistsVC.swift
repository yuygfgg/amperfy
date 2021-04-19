import UIKit
import CoreData

class PlaylistsVC: SingleFetchedResultsTableViewController<PlaylistMO> {

    private var fetchedResultsController: PlaylistFetchedResultsController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultsController = PlaylistFetchedResultsController(managedObjectContext: appDelegate.storage.context, isGroupedInAlphabeticSections: true)
        singleFetchedResultsController = fetchedResultsController
        
        configureSearchController(placeholder: "Search in \"Playlists\"", scopeButtonTitles: ["All", "User Playlists", "Smart Playlists"])
        tableView.register(nibName: PlaylistTableCell.typeName)
        tableView.rowHeight = PlaylistTableCell.rowHeight
        self.refreshControl?.addTarget(self, action: #selector(Self.handleRefresh), for: UIControl.Event.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchedResultsController.fetch()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PlaylistTableCell = dequeueCell(for: tableView, at: indexPath)
        let playlist = fetchedResultsController.getWrappedEntity(at: indexPath)
        cell.display(playlist: playlist)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playlist = fetchedResultsController.getWrappedEntity(at: indexPath)
        performSegue(withIdentifier: Segues.toPlaylistDetail.rawValue, sender: playlist)
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let playlist = fetchedResultsController.getWrappedEntity(at: indexPath)
            appDelegate.persistentLibraryStorage.deletePlaylist(playlist)
            appDelegate.persistentLibraryStorage.saveContext()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.toPlaylistDetail.rawValue {
            let vc = segue.destination as! PlaylistDetailVC
            let playlist = sender as? Playlist
            vc.playlist = playlist
        }
    }

    @objc func handleRefresh(refreshControl: UIRefreshControl) {
        appDelegate.storage.persistentContainer.performBackgroundTask() { (context) in
            let backgroundLibrary = LibraryStorage(context: context)
            let syncer = self.appDelegate.backendApi.createLibrarySyncer()
            
            let oldSortedPlaylists = backgroundLibrary.getPlaylists().sortAlphabeticallyAscending()
            syncer.syncDownPlaylistsWithoutSongs(libraryStorage: backgroundLibrary)
            let newSortedPlaylists = backgroundLibrary.getPlaylists().sortAlphabeticallyAscending()
            let newAddedPlaylists = newSortedPlaylists.filter{ !oldSortedPlaylists.contains($0) }

            for addedPlaylist in newAddedPlaylists {
                syncer.syncDown(playlist: addedPlaylist, libraryStorage: backgroundLibrary, statusNotifyier: nil)
            }
            
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
        }
    }

    override func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        let playlistSearchCategory = PlaylistSearchCategory(rawValue: searchController.searchBar.selectedScopeButtonIndex) ?? PlaylistSearchCategory.defaultValue
        fetchedResultsController.search(searchText: searchText, playlistSearchCategory: playlistSearchCategory)
        tableView.reloadData()
    }
    
}
