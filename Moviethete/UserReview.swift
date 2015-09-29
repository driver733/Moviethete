//
//  UserReview.swift
//  Moviethete
//
//  Created by Mike on 9/4/15.
//  Copyright © 2015 BIBORAM. All rights reserved.
//

import Foundation
import Parse


public struct UserReview {
  
  static var sharedInstance = UserReview()
  
  var starRating: Int?
  /// The star rating representation. Takes Int values from 1 to 5.
  var title: String?
  /// The title of the review
  var review: String?
  /// The review of the movie
  
  
  init(){}
  
  
  init(theStarRating: Int, theTitle: String, theReview: String) {
    starRating = theStarRating
    title = theTitle
    review = theReview
  }
  
  
  
  
  
  
  
  func uploadReview(post: Post, rating: Int, reviewTitle: String, review: String) -> BFTask {
    let mainTask = BFTaskCompletionSource()
    let reviewsRelation = PFUser.currentUser()?.relationForKey("posts")
    let parsePost = PFObject(className: "Post")
    parsePost["userReview"] = [rating, reviewTitle, review]
    parsePost["trackID"] = post.trackID!
    parsePost["createdBy"] = PFUser.currentUser()!
    parsePost.saveInBackground().continueWithBlock { (task: BFTask!) -> AnyObject! in
      if task.error == nil {
        reviewsRelation?.addObject(parsePost)
        
//        do {
//          try PFUser.currentUser()!.save()
//        }
//        catch {
//          
//        }
        
        return PFUser.currentUser()?.saveInBackground()
      } else {
        mainTask.setError(task.error)
        return nil
      }
    }.continueWithBlock { (task: BFTask!) -> AnyObject! in
      if task.error == nil {
        PFCloud.callFunctionInBackground("appendNewUserPostToFollowersFeeds",
          withParameters: ["currentUserObjectId" : (PFUser.currentUser()?.objectId)!],
          block: { (result: AnyObject?, error: NSError?) -> Void in
            if error == nil {
              mainTask.setResult(nil)
            }
        })
        return nil
      } else {
        mainTask.setError(task.error)
        return nil
      }
  }

    return mainTask.task

    
  }
  
  
  
  
  
}



