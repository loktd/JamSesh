//
//  AddSongsViewController.swift
//  JamSesh
//
//  Created by Micaella Morales on 4/26/19.
//  Copyright © 2019 Monali Chuatico. All rights reserved.
//

import UIKit
import Parse

class AddSongsViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var playlist: PFObject?
    var songs = [PFObject]()
    var filteredSongs = [PFObject]()
    var searchBarBeginEditing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.dataSource = self
        searchBar.delegate = self
        
        loadSongs()
        filteredSongs = songs
        
        tableView.isHidden = true
    }
    
    func loadSongs() {
        let query = PFQuery(className: "Songs")
        query.findObjectsInBackground { (songs, error) in
            if songs != nil {
                self.songs = songs!
                print("Retrieved Songs!")
            }
            else {
                print("No songs found!")
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchBarBeginEditing {
            return filteredSongs.count
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongSearchCell") as! SongSearchCell
        let song = filteredSongs[indexPath.row]
        let songTitle = song["songTitle"] as! String
        cell.songTitleLabel.text = songTitle
        
        cell.playlist = playlist
        cell.song = song
        
        let playlistSongs = playlist?["songs"] as? [PFObject] ?? []
        if !playlistSongs.isEmpty {
            for playlistSong in playlistSongs {
                if playlistSong.objectId == song.objectId {
                    cell.inPlaylist = true
                    cell.addSongButton.setImage(UIImage(named: "check"), for: UIControl.State.normal)
                    break
                }
            }
        }
        
        return cell
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredSongs = songs.filter({ (song) -> Bool in
            let songTitle = song["songTitle"] as! String
            return songTitle.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        })
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBarBeginEditing = false
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        tableView.isHidden = true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBarBeginEditing = true
        searchBar.showsCancelButton = true
        tableView.isHidden = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        tableView.isHidden = false
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
