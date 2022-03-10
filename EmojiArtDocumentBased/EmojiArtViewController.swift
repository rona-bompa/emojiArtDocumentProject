//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Rona Bompa on 04.03.2022.
//

import UIKit
import Foundation

class EmojiArtViewController: UIViewController, UIDropInteractionDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate {

    // MARK: - Model

    var emojiArt: EmojiArt? {
        get {
            if let url  = emojiArtBackgroundImage.url {
                let emojis = emojiArtView.subviews.compactMap { $0 as? UILabel }.compactMap { EmojiArt.EmojiInfo(label: $0) } // flatMap like map, but ignores if the func return nil
                return EmojiArt(url: url, emojis: emojis)
            }
            return nil
        }
        set {
            emojiArtBackgroundImage = (nil, nil)
            emojiArtView.subviews.compactMap{ $0 as? UILabel }.forEach { $0.removeFromSuperview() }
            if let url = newValue?.url {
                imageFetcher = ImageFetcher(fetch: url) { ( url, image ) in
                    DispatchQueue.main.async {
                        self.emojiArtBackgroundImage = (url, image)
                        newValue?.emojis.forEach {
                            let attributedText = $0.text.attributedString(withTextStyle: .body, ofSize: CGFloat($0.size))
                            self.emojiArtView.addLabel(with: attributedText, centeredAt: CGPoint(x: $0.x, y: $0.y))
                        }
                    }
                }
            }
        }
    }

    private var _emojiArtBackgroundImageURL: URL?  // _ means it's in the background, we never set this

    var imageFetcher: ImageFetcher!
    var emojis = "🧸🔑❤️🇷🇴😊🦊🎈☀️🫐☎️🎹🥇🎬🏐🏀🏓🛼🧚🏻‍♀️👨‍🚀👩‍💻👍👀".map { String($0) } // each emoji is a string with map & this closure

    var document: EmojiArtDocument?

    @IBAction func save(_ sender: UIBarButtonItem? = nil) {
        document?.emojiArt = emojiArt
        if document?.emojiArt != nil {
            document?.updateChangeCount(.done) // can be undo, redo or done
        }
    }

    @IBAction func close(_ sender: UIBarButtonItem) {
        save()
        if document?.emojiArt != nil {
            document?.thumbnail = emojiArtView.snapshot
        }
        dismiss(animated: true) {
            self.document?.close()
        }
        document?.close()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        document?.open { success in
            if success {
                self.title = self.document?.localizedName
                self.emojiArt = self.document?.emojiArt
            }
        }
    }


    @IBOutlet weak var dropZone: UIView! {
        didSet {
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }

    var emojiArtView = EmojiArtView()

    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!

    @IBOutlet weak var emojiCollectionView: UICollectionView! {
        didSet {
            emojiCollectionView.dataSource = self
            emojiCollectionView.delegate = self
            emojiCollectionView.dragDelegate = self
            emojiCollectionView.dropDelegate = self
            emojiCollectionView.dragInteractionEnabled = true
        }
    }

    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(emojiArtView)
        }
    }

    private var addingEmoji = false
    @IBAction func addEmoji(_ sender: UIButton) {
        addingEmoji = true
        emojiCollectionView.reloadSections(IndexSet(integer: 0))
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return emojis.count
        default: return 0
        }
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewWidth.constant = scrollView.contentSize.width
        scrollViewHeight.constant = scrollView.contentSize.height
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }

    var emojiArtBackgroundImage: (url: URL?, image: UIImage?) {
        get {
            return (_emojiArtBackgroundImageURL, emojiArtView.backgroundImage)
        }
        set {
            _emojiArtBackgroundImageURL = newValue.url
            scrollView?.zoomScale = 1.0
            emojiArtView.backgroundImage = newValue.image
            let size = newValue.image?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollViewWidth?.constant = size.width
            scrollViewHeight?.constant = size.height
            scrollView?.contentSize = size
            if let dropZone = self.dropZone, size.width > 0, size.height > 0 {
                scrollView?.zoomScale = max(dropZone.bounds.size.width / size.width, dropZone.bounds.size.height / size.height)
            }
        }
    }

    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        imageFetcher = ImageFetcher() { (url, image) in
            DispatchQueue.main.async {
                self.emojiArtBackgroundImage = (url, image)
            }
        }

        session.loadObjects(ofClass: NSURL.self) { nsurls in
            if let url = nsurls.first as? URL {
//                self.imageFetcher.fetch(url)
                DispatchQueue.global(qos: .userInitiated).async {
                    if let imageData = try? Data(contentsOf: url.imageURL) {

                    }
                }
            }
        }

        session.loadObjects(ofClass: UIImage.self) { images in
            if let image = images.first as? UIImage {
                self.imageFetcher.backup = image
            }
        }
    }

    private var font: UIFont {
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(54.0))
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
            if let emojiCell = cell as? EmojiCollectionViewCell {
                let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font: font])
                emojiCell.label.attributedText = text
            }
            return cell
        } else if addingEmoji {
            self.addingEmoji = false
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiInputCell", for: indexPath)
            if let inputCell = cell as? TextFieldCollectionViewCell {  // IMPORTANT IF WE WANT TO TALK TO THE COLLECTIONVIEW
                inputCell.resignationHandler = { [weak self, unowned inputCell] in
                    if let text = inputCell.textField.text {
                        self?.emojis = (text.map { String($0) }  + self!.emojis).uniquified
                    }
                    self?.emojiCollectionView.reloadData()
                }
            }
            return cell
        } else {
            print("Add Emoji Cell")
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddEmojiButtonCell", for: indexPath)
            return cell
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionview: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if addingEmoji && indexPath.section == 0 {
            return CGSize(width: 300, height: 80)
        } else {
            return CGSize(width: 80, height: 80)
        }
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionview: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let inputCell = cell as? TextFieldCollectionViewCell {
            inputCell.textField.becomeFirstResponder()
        }
    }

    // MARK: - UICollecitonViewDragDelegate
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }

    // all it is required for dragging
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }

    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
    // MARK: - UICollectionViewDragDelegate
        if !addingEmoji, let attributedString  = (emojiCollectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell)?.label.attributedText {
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributedString)) // this creates the drag item
            dragItem.localObject = attributedString // just grabbing the local object
            return [dragItem]
        } else {
            return []
        }
    }

    // MARK: - UICollectionViewDropDelegate
    // required for dropping
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let indexPath = destinationIndexPath, indexPath.section == 1 {
            let isSelf = (session.localDragSession?.localContext as? UICollectionView) ==  collectionView
            return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .cancel)
        }
    }

    // !don't reload data in the middle of a drag!
    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
        // the coordinator is gonna give all the info we need for the drop
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                if let attributedString = item.dragItem.localObject as? NSAttributedString {
                    collectionView.performBatchUpdates({ // neccessary if we do multiple adjustments to table or collection view
                        // it will do them all as one operation:
                        emojis.remove(at: sourceIndexPath.item)
                        emojis.insert(attributedString.string, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    })  // is gonna animate
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath) // is gonna drop
                }
            } else {
                let placeholderContext = coordinator.drop(
                    item.dragItem,
                    to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell"))
                item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self) { (provider, error) in
                    DispatchQueue.main.async {
                        if let attributedString = provider as? NSAttributedString {
                            placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                                self.emojis.insert(attributedString.string, at: insertionIndexPath.item)
                            })
                        } else {
                            placeholderContext.deletePlaceholder()
                        }
                    }
                }
            }
        }
    }
}

extension EmojiArt.EmojiInfo {
    init?(label: UILabel) {
        if let attributedText = label.attributedText, let font = attributedText.font {
            x = Int(label.center.x)
            y = Int(label.center.y)
            text = attributedText.string
            size = Int(font.pointSize)
        } else {
            return nil
        }
    }
}
