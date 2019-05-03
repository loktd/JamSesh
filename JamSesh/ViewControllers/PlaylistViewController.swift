//
//  PlaylistViewController.swift
//  JamSesh
//
//  Created by Micaella Morales on 4/25/19.
//  Copyright © 2019 Monali Chuatico. All rights reserved.
//

import UIKit
import Parse

class PlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var playlistNameLabel: UILabel!
    @IBOutlet weak var playAllButton: UIButton!
    
    var playlist: PFObject?
    var songs: [PFObject]?
    var filenames = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        playlistNameLabel.text = playlist!["playlistName"] as? String
        songs = playlist!["songs"] as? [PFObject] ?? []
        self.filenames = self.getFilenames()
        addSongs()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        songs = playlist!["songs"] as? [PFObject] ?? []
        self.filenames = self.getFilenames()
        tableView.reloadData()
        
        if SoundPlayer.sharedInstance.isQueuePlaying {
            playAllButton.setImage(UIImage(named: "pause-1"), for: UIControl.State.normal)
        }
        else {
            playAllButton.setImage(UIImage(named: "play-1"), for: UIControl.State.normal)
        }
    }
    
    func getFilenames()-> [String]{
        var fileNames = [String]()
        for song in self.songs! {
            let filename = song["fileName"] as! String
            fileNames.append(filename)
        }
        
        return fileNames
        
    }
    
    func addSongs() {
        if songs != nil {
            for filename in filenames {
                SoundPlayer.sharedInstance.addSong(fileName: filename)
            }
        }
    }
    
    @IBAction func onPlayAllButton(_ sender: Any) {
        if songs != nil {
            SoundPlayer.sharedInstance.playAllSongs()
            if SoundPlayer.sharedInstance.isQueuePlaying {
                playAllButton.setImage(UIImage(named: "pause-1"), for: UIControl.State.normal)
            }
            else {
                playAllButton.setImage(UIImage(named: "play-1"), for: UIControl.State.normal)
            }
        }
    }
    
    @IBAction func forwardButton(_ sender: UIButton) {
        SoundPlayer.sharedInstance.nextSong()
    }
    
    @IBAction func previousButton(_ sender: Any) {
        SoundPlayer.sharedInstance.prevSong()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell") as! SongCell
        let song = songs![indexPath.row]
        cell.song = song
        
        let songTitle = song["songTitle"] as? String
        let artist = song["Artist"] as? String
        cell.songTitleLabel.text = songTitle
        cell.artistLabel.text = artist
        
        if songTitle == UserDefaults.standard.string(forKey: "SongTitle") {
            if UserDefaults.standard.bool(forKey: "Play") == true {
                cell.playButton.setImage(UIImage(named: "pause"), for: UIControl.State.normal)
            }
            else {
                cell.playButton.setImage(UIImage(named: "play"), for: UIControl.State.normal)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            playlist?.remove(songs![indexPath.row], forKey: "songs")
            playlist?.saveInBackground(block: { (success, error) in
                if success {
                    //remove song from queueplayer and filename
                    let filename = self.filenames[indexPath.row] as! String
                    SoundPlayer.sharedInstance.removeSong(filename: filename, index: indexPath.row)
                    self.filenames.remove(at: indexPath.row)
                    
                    //reload songs from the playlist
                    self.songs = self.playlist!["songs"] as? [PFObject] ?? []
                    
                    //delete row
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    print("The song was successfully deleted from playlist")
                }
                else {
                    print("Error encountered in deleting song from playlist")
                }
            })
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        let addSongsViewController = segue.destination as! AddSongsViewController
        
        // Pass the selected object to the new view controller.
        addSongsViewController.playlist = playlist
    }
    
}
