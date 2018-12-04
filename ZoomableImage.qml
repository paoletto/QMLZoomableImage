/*
    Released under Mozilla Public License v2.0
*/

import QtQuick 2.7

// check also https://github.com/0312birdzhang/harbour-one/blob/master/qml/pages/ImagePage.qml
// https://gist.github.com/torarnv/2705676
// http://doc.qt.io/qt-5/qtquick-touchinteraction-pincharea-flickresize-qml.html

Rectangle {
    anchors.fill: parent
    id: rect
    color: "black"
    property alias backgroundColor: rect.color
    property alias source: ima.source

    property real minScaleFactor : Math.min(width / ima.sourceSize.width, height / ima.sourceSize.height)
    property real scaleFactor: minScaleFactor

    property real _scaleFactor : minScaleFactor

    function _fuzzy_compare(val, ref, tol) {
        var tolerance = 0.0001
        if (tol !== undefined)
            tolerance = tol
        if ((val >= ref - tolerance) && (val <= ref + tolerance))
            return true;
        return false;
    }

    function _zoom(newScale, pos) {
        if (pos === Qt.point(-1,-1))
            pos = Qt.point(flickable.contentX + flickable.leftMargin + flickable.width * 0.5,
                           flickable.contentY + flickable.topMargin + flickable.height * 0.5)

        pinchArea.startPinch()
        pinchArea.updatePinch(pos, newScale / _scaleFactor)
        flickable.returnToBounds()
    }

    onScaleFactorChanged: {
        if (!isNaN(scaleFactor) && !_fuzzy_compare(scaleFactor, _scaleFactor)) {
            //console.log(scaleFactor, _scaleFactor, minScaleFactor)
            _zoom(scaleFactor, Qt.point(-1,-1))
        }
    }
    on_ScaleFactorChanged: {
        if (scaleFactor !== _scaleFactor)
            scaleFactor = _scaleFactor
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: Math.max(ima.sourceSize.width * _scaleFactor) //, parent.width)
        contentHeight: Math.max(ima.sourceSize.height * _scaleFactor) //, parent.height)
        topMargin: Math.max(0, (height - contentHeight) * 0.5)
        leftMargin: Math.max(0, (width - contentWidth) * 0.5)

        PinchArea {
            id: pinchArea
            width: flickable.contentWidth
            height: flickable.contentHeight

            property real initialContentX
            property real initialContentY
            property real initialScale

            onPinchStarted: {
                startPinch()
            }

            onPinchUpdated: {
                // adjust content pos due to drag
                updatePinch(pinch.center, pinch.scale)
            }

            onPinchFinished: {
                // Move its content within bounds.
                flickable.returnToBounds()
            }

            function startPinch() {
                pinchArea.initialContentX = flickable.contentX
                pinchArea.initialContentY = flickable.contentY
                pinchArea.initialScale = _scaleFactor
            }

            function finishPinch() {
                flickable.returnToBounds()
            }

            function updatePinch(pos, zoomFactor) {
                var xpos = pos.x - flickable.contentX - flickable.leftMargin
                var ypos = pos.y - flickable.contentY - flickable.topMargin

                var xposImage = (flickable.contentX + flickable.leftMargin + xpos) / flickable.contentWidth
                var yposImage = (flickable.contentY + flickable.topMargin + ypos) / flickable.contentHeight

                rect._scaleFactor = Math.max(minScaleFactor, zoomFactor * pinchArea.initialScale)

                flickable.contentX =  xposImage * flickable.contentWidth - xpos - flickable.leftMargin
                flickable.contentY = yposImage * flickable.contentHeight - ypos - flickable.topMargin
            }

            Rectangle {
                id: imaRect
                width: flickable.contentWidth
                height: flickable.contentHeight
                color: "transparent"
                Image {
                    id:ima
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop

                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                            flickable.contentWidth = ima.sourceSize.width
                            flickable.contentHeight = ima.sourceSize.height
                        }
                        onWheel: {
                            if (wheel.modifiers & Qt.ControlModifier) {
                                _zoom((1 + 0.2 * wheel.angleDelta.y / 120) * _scaleFactor,
                                      Qt.point(wheel.x, wheel.y))
                            }
                        }
                    }
                }
            }
        }
    }
}
