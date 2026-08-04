import QtQuick
import QtMultimedia

/**
 * Standalone hover preview for video wallpaper tiles in the wallpaper strip.
 * Kept out of the pill module's type graph so the QtMultimedia plugin loads
 * only when a video tile is first hovered, not at daemon startup.
 */
Item {
    property string source: ""

    VideoOutput {
        id: videoPreview
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: vidPlayer.playbackState === MediaPlayer.PlayingState
    }

    MediaPlayer {
        id: vidPlayer
        videoOutput: videoPreview
        loops: MediaPlayer.Infinite
        source: parent.source
        onMediaStatusChanged: if (mediaStatus === MediaPlayer.LoadedMedia) play()
    }
}
