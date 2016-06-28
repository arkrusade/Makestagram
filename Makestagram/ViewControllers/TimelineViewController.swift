import UIKit
import Parse
import ConvenienceKit

class TimelineViewController: UIViewController, TimelineComponentTarget {
	var photoTakingHelper: PhotoTakingHelper?
	let defaultRange: Range<Int> = 0...4
	/**
	Defines the additional amount of items that get loaded
	subsequently when a user reaches the last entry.
	*/
	let additionalRangeSize = 5
	@IBOutlet weak var tableView: UITableView!
	var timelineComponent: TimelineComponent<Post, TimelineViewController>!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		timelineComponent = TimelineComponent(target: self)
		
		self.tabBarController?.delegate = self
	}
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		timelineComponent.loadInitialIfRequired()
	}
	/// Defines the range of the timeline that gets loaded initially.
	
	/// A reference to the TableView to which the Timeline Component is applied.
	/**
	This method should load the items within the specified range and call the
	`completionBlock`, with the items as argument, upon completion.
	*/
	func loadInRange(range: Range<Int>, completionBlock: ([Post]?) -> Void)
	{
		ParseHelper.timelineRequestForCurrentUser(range) { (result: [PFObject]?, error: NSError?) -> Void in
			if let error = error {
				ErrorHandling.defaultErrorHandler(error)
			}
			let posts = result as? [Post] ?? []
			// 3
			completionBlock(posts)
		}
	}
}
//MARK: UI Table View Delegate
extension TimelineViewController: UITableViewDelegate {
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerCell = tableView.dequeueReusableCellWithIdentifier("PostHeader") as! PostSectionHeaderView
		
		let post = self.timelineComponent.content[section]
		headerCell.post = post
			
		return headerCell
	}
	
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 40
	}
	func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		timelineComponent.targetWillDisplayEntry(indexPath.section)
	}
	
}
//MARK: UI Table View Data Source

extension TimelineViewController: UITableViewDataSource {
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return self.timelineComponent.content.count
	}
	
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as! PostTableViewCell
				
		let post = timelineComponent.content[indexPath.section]
		post.downloadImage()
		post.fetchLikes()
		cell.post = post
			
		return cell
	}
}


// MARK: Tab Bar Delegate

extension TimelineViewController: UITabBarControllerDelegate {
	
	func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
		if (viewController is PhotoViewController) {
			takePhoto()
			return false
		} else {
			
			return true
		}
	}
	func takePhoto() {
		photoTakingHelper = PhotoTakingHelper(viewController: self.tabBarController!) { (image: UIImage?) in
			let post = Post()
			// 1
			post.image.value = image!
			post.uploadPost()
		}
	}
}