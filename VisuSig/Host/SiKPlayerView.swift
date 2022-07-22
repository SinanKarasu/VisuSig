//
//  SiKPlayerView.swift
//  SiKAUv3HostRedo
//
//  Created by Sinan Karasu on 1/26/22.
//

import SwiftUI


//var episode: Episode
//@State private var playState: PlayState = .paused
//
//var body: some View {
//    VStack {
//        Text(episode.title)
//        Text(episode.showTitle)
//        PlayButton(playState: $playState)
//    }
//    .onChange(of: playState) { [playState] newState in
//        model.playStateDidChange(from: playState, to: newState)
//    }
//}

struct SiKPlayerView: View {
    @State var playing = false
    @ObservedObject var audioUnitManager: AudioUnitManager
    var body: some View {
        Button(action: {
            DispatchQueue.main.async {
                self.playing = self.audioUnitManager.togglePlayback()
            }
        }) {
            Image(systemName: self.playing == false ? "play" : "pause")
                .imageScale(.large)
                .frame(width: 64, height: 64)
        }

    }
}

struct SiKPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        SiKPlayerView( audioUnitManager: AudioUnitManager())
    }
}
