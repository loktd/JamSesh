//
//  ProfileViewController.swift
//  JamSesh
//
//  Created by Monali Chuatico on 4/10/19.
//  Copyright © 2019 Monali Chuatico. All rights reserved.
//

import UIKit
import Parse
import AlamofireImage

class ProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var followersCountLabel: UILabel!
    @IBOutlet weak var followingCountLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var songView: UIView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    let currUser = PFUser.current()!
    var currUserInfo: PFObject?
    var userPlaylists = [PFObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        profileImage.layer.cornerRadius = profileImage.frame.size.width/2
        
        //loads the profile image of user
        let imageFile = currUser["image"] as? PFFileObject ?? nil
        if imageFile != nil {
            let urlString = imageFile!.url!
            let url = URL(string: urlString)!
            profileImage.af_setImage(withURL: url)
        }
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        loadPlaylists()
        
        if UserDefaults.standard.bool(forKey: "Play") == false {
            songView.isHidden = true
        }
        
        //sets the layout of the collection view
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 15
        layout.sectionInset = UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15)
        let width = (view.frame.size.width - layout.minimumInteritemSpacing*3) / 2
        layout.itemSize = CGSize(width: width, height: width)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        loadUserInfo()
        if UserDefaults.standard.bool(forKey: "Play") == true {
            songTitleLabel.text = UserDefaults.standard.string(forKey: "SongTitle")
            artistLabel.text = UserDefaults.standard.string(forKey: "Artist")
            playButton.setImage(UIImage(named: "pause"), for: UIControl.State.normal)
            songView.isHidden = false
        }
        else {
            playButton.setImage(UIImage(named: "play"), for: UIControl.State.normal)
        }
    }
    
    
    
    func loadUserInfo() {
        usernameLabel.text = currUser.username
        
        let query = PFQuery(className: "UserInfo")
        query.includeKey("user")
        query.findObjectsInBackground { (usersInfo, error) in
            if usersInfo != nil {
                for userInfo in usersInfo! {
                    let user = userInfo["user"] as! PFUser
                    if user.objectId == self.currUser.objectId {
                        self.currUserInfo = userInfo
                        let followersCount = userInfo["followersCount"] as? Int ?? 0
                        let followingCount = userInfo["followingCount"] as? Int ?? 0
                        
                        self.followersCountLabel.text = "\(String(followersCount)) followers"
                        self.followingCountLabel.text = "\(String(followingCount)) following"
                        break
                    }
                }
            }
        }
    }
    
    @IBAction func changeProfileImage(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        }
        else {
            picker.sourceType = .photoLibrary
        }
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.editedImage] as! UIImage
        
        let size = CGSize(width: 300, height: 300)
        let scaledImage = image.af_imageAspectScaled(toFill: size)
        
        profileImage.image = scaledImage
        
        let imageData = profileImage.image!.pngData()
        let file = PFFileObject(data: imageData!)
        
        currUser["image"] = file
        
        currUser.saveInBackground { (success, error) in
            if success {
                print("saved!")
            }
            else {
                print("error!")
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func loadPlaylists() {
        let query = PFQuery(className:"Playlists")
        query.includeKeys(["author", "songs"])
        query.addDescendingOrder("createdAt")
        userPlaylists.removeAll()
        query.findObjectsInBackground { (playlists, error) in
            if playlists != nil {
                for playlist in playlists! {
                    let author = playlist["author"] as! PFUser
                    if (author.objectId! == self.currUser.objectId) {
                        self.userPlaylists.append(playlist)
                    }
                }
                print("Retrieved user playlists")
                self.collectionView.reloadData()
            }
            else {
                print("Error: \(String(describing: error))")
            }
        }
    }
    
    @IBAction func createPlaylist(_ sender: Any) {
        let alert = UIAlertController(title: "Enter name of playlist", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Playlist"
        })
        
        alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { action in
            
            if let name = alert.textFields?.first?.text {
                print("Name of playlist: \(name)")
                
                let playlist = PFObject(className: "Playlists")
                playlist["playlistName"] = name
                playlist["author"] = self.currUser
                
                playlist.saveInBackground(block: { (success, error) in
                    if success {
                        self.loadPlaylists()
                        print("saved!")
                    }
                    else {
                        print("error!")
                    }
                })
            }
        }))
        self.present(alert, animated: true)
    }
    
    @IBAction func onPlayButton(_ sender: Any) {
        SoundPlayer.sharedInstance.playSong()
        
        if SoundPlayer.sharedInstance.isAudioPlaying {
            playButton.setImage(UIImage(named: "pause"), for: UIControl.State.normal)
            UserDefaults.standard.set(true, forKey: "Play")
        }
        else {
            playButton.setImage(UIImage(named: "play"), for: UIControl.State.normal)
            UserDefaults.standard.set(false, forKey: "Play")
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userPlaylists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaylistCell", for: indexPath) as! PlaylistCell
        let playlist = userPlaylists[indexPath.row]
        cell.playlistLabel.text = playlist["playlistName"] as? String
        
        return cell
    }
    
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Find the user
        let cell = sender as! UICollectionViewCell
        let indexPath = collectionView.indexPath(for: cell)!
        let playlist = userPlaylists[indexPath.row]
        
        // Get the new view controller using segue.destination.
        let playlistViewController = segue.destination as! PlaylistViewController
        
        // Pass the selected object to the new view controller.
        playlistViewController.playlist = playlist
     }
    
    
}
