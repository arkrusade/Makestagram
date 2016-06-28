import Bond
import Parse
import ConvenienceKit
// 1
class Post : PFObject, PFSubclassing {
    
    // 2
    @NSManaged var imageFile: PFFile?
    @NSManaged var user: PFUser?
    var image: Observable<UIImage?> = Observable(nil)
    var photoUploadTask: UIBackgroundTaskIdentifier?
    var likes: Observable<[PFUser]?> = Observable(nil)
	static var imageCache: NSCacheSwift<String, UIImage>!
	
	override init()
	{
		super.init()
	}
	override class func initialize() {
		var onceToken : dispatch_once_t = 0;
		dispatch_once(&onceToken) {
			// inform Parse about this subclass
			self.registerSubclass()
			// 1
			Post.imageCache = NSCacheSwift<String, UIImage>()
		}
	}
	func fetchLikes() {
        // 1
//        if (likes.value == nil) {
//            return
//        }
        
        // 2
        ParseHelper.likesForPost(self, completionBlock: { (likes: [PFObject]?, error: NSError?) -> Void in
			if let error = error {
				ErrorHandling.defaultErrorHandler(error)
			}
            let validLikes = likes?.filter { like in like[ParseHelper.ParseLikeFromUser] != nil }
            
            // 4
            self.likes.value = validLikes?.map { like in
                let fromUser = like[ParseHelper.ParseLikeFromUser] as! PFUser
                
                return fromUser
            }
        })
    }
    
    func doesUserLikePost(user: PFUser) -> Bool {
        if let likes = likes.value {
            return likes.contains(user)
        } else {
            return false
        }
    }
    //MARK: PFSubclassing Protocol
    
    // 3
    static func parseClassName() -> String {
        return "Post"
    }
	
    

    func downloadImage() {
		// 1
		image.value = Post.imageCache[self.imageFile!.name]
		
		// if image is not downloaded yet, get it
		if (image.value == nil) {
			
			imageFile?.getDataInBackgroundWithBlock { (data: NSData?, error: NSError?) -> Void in
				if let error = error {
					ErrorHandling.defaultErrorHandler(error)
				}
				if let data = data {
					let image = UIImage(data: data, scale:1.0)!
					self.image.value = image
					// 2
					Post.imageCache[self.imageFile!.name] = image
				}
			}
		}
    }
    func toggleLikePost(user: PFUser) {
        if (doesUserLikePost(user)) {
            // if post is liked, unlike it now
            // 1
            likes.value = likes.value?.filter { $0 != user }
            ParseHelper.unlikePost(user, post: self)
        } else {
            // if this post is not liked yet, like it now
            // 2
            likes.value?.append(user)
            ParseHelper.likePost(user, post: self)
        }
    }

    func uploadPost()
    {
        if let image = image.value {
            guard let imageData = UIImageJPEGRepresentation(image, 0.8) else {return}
            guard let imageFile = PFFile(name: "image.jpg", data: imageData) else {return}
            
            photoUploadTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler{()-> Void in UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
            }
            
            user = PFUser.currentUser()
            self.imageFile = imageFile
            saveInBackgroundWithBlock{ (success: Bool, error: NSError?) in
				if let error = error {
					ErrorHandling.defaultErrorHandler(error)
				}
				UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
            }   
        }
        
    }
    
}