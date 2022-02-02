import UIKit

class GenreTableCell: BasicTableCell {
    
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var artworkImage: LibraryEntityImage!
    @IBOutlet weak var infoLabel: UILabel!
    
    static let rowHeight: CGFloat = 48.0 + margin.bottom + margin.top
    
    private var genre: Genre?
    private var rootView: UITableViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture))
        self.addGestureRecognizer(longPressGesture)
    }
    
    func display(genre: Genre, rootView: UITableViewController) {
        self.genre = genre
        self.rootView = rootView
        genreLabel.text = genre.name
        artworkImage.displayAndUpdate(entity: genre, via: (UIApplication.shared.delegate as! AppDelegate).artworkDownloadManager)
        var infoText = ""
        if appDelegate.backendProxy.selectedApi == .ampache {
            if genre.artists.count == 1 {
                infoText += "1 Artist"
            } else {
                infoText += "\(genre.artists.count) Artists"
            }
            infoText += " \(CommonString.oneMiddleDot) "
        }
        if genre.albums.count == 1 {
            infoText += "1 Album"
        } else {
            infoText += "\(genre.albums.count) Albums"
        }
        infoText += " \(CommonString.oneMiddleDot) "
        if genre.songs.count == 1 {
            infoText += "1 Song"
        } else {
            infoText += "\(genre.songs.count) Songs"
        }
        infoLabel.text = infoText
    }
    
    @objc func handleLongPressGesture(gesture: UILongPressGestureRecognizer) -> Void {
        if gesture.state == .began {
            displayMenu()
        }
    }
    
    func displayMenu() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        guard let genre = genre, let rootView = rootView, rootView.presentingViewController == nil else { return }
        let detailVC = LibraryEntityDetailVC()
        detailVC.display(genre: genre, on: rootView)
        rootView.present(detailVC, animated: true)
    }

}
