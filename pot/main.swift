#!/usr/bin/swift

//
//  main.swift
//  pot
//
//  Tool to resize images to the nearest power of two.
//
//  Usage: run in a folder to automatically rescale all .jpg files down to their
//  nearest power of two.
//
//  Specify '-up' as an argument to scale up instead.
//
//  Note: Requires ImageMagick to be installed and available at path: /usr/local/bin
//
//  Created by David Haynes on 12/03/2017.
//  Copyright © 2017 MBP Consulting Ltd. All rights reserved.
//

import Foundation

enum Dimension {
    case width
    case height
}

enum ScaleDirection {
    case up
    case down
}

func getDimension(imagePath: String, dimension: Dimension, direction: ScaleDirection) -> Int {
    let convertPath = "/usr/local/bin/convert"
    var formatArguments = "\"%[fx:2^({dir}(log({dim})/log(2)))]\""

    switch (dimension) {
    case .width:
        formatArguments = formatArguments.replacingOccurrences(of: "{dim}", with: "w")
    case .height:
        formatArguments = formatArguments.replacingOccurrences(of: "{dim}", with: "h")
    }

    switch (direction) {
    case .up:
        formatArguments = formatArguments.replacingOccurrences(of: "{dir}", with: "ceil")
    case .down:
        formatArguments = formatArguments.replacingOccurrences(of: "{dir}", with: "floor")
    }

    let task = Process()
    let pipe = Pipe()

    task.launchPath = convertPath
    let imagePath = imagePath
    task.arguments = [imagePath, "-format", formatArguments, "info:"]
    task.standardOutput = pipe
    task.launch()


    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
        let trimmedOutput = output.replacingOccurrences(of: "\"", with: "")
        if let size = Int(trimmedOutput as String) {
            return size
        } else {
            print("Output could not be converted to number")
        }
    } else {
        print("Invalid output")
    }
    return 0
}

func resizeImage(imagePath: String, width: Int, height: Int, outputFolder: String) {
    let widthString = String(width)
    let heightString = String(height)

    let convertPath = "/usr/local/bin/convert"
    var resizeArguments = "{w}x{h}!"
    resizeArguments = resizeArguments.replacingOccurrences(of: "{w}", with: widthString)
    resizeArguments = resizeArguments.replacingOccurrences(of: "{h}", with: heightString)

    let fileExtension = (imagePath as NSString).pathExtension
    let fileNamePath = (imagePath as NSString).deletingPathExtension
    let fileName = (fileNamePath as NSString).lastPathComponent
    let fileFolder = (imagePath as NSString).deletingLastPathComponent
    let outputImagePath = String(format: "%@/%@/%@-%dx%d.%@", fileFolder, outputFolder, fileName, width, height, fileExtension)

    print("Writing:", outputImagePath)
    
    let task = Process()
    task.launchPath = convertPath
    task.arguments = [imagePath, "-resize", resizeArguments, outputImagePath]
    task.launch()
}

func createDir(dirName: String) {
    if !(FileManager.default.fileExists(atPath: dirName)) {
        do {
            try FileManager.default.createDirectory(atPath: dirName,
                                                    withIntermediateDirectories: false,
                                                    attributes: nil)
        } catch let error as NSError {
            print("Error creating directory: \(error.localizedDescription)")
        }
    }
}

func listAllFiles(atPath path: String, withExtension fileExtension: String) -> [String] {
    let pathURL = URL(fileURLWithPath: path, isDirectory: true)

    print("Searching for images in:", pathURL.absoluteString)

    do {
        let directoryContents = try FileManager.default.contentsOfDirectory(at: pathURL, includingPropertiesForKeys: nil, options: [])
        let jpgFiles = directoryContents.filter{ $0.pathExtension == "jpg" }.map{ $0.relativePath }
        return jpgFiles
    } catch let error as NSError {
        print(error.localizedDescription)
    }
    return []
}

let arguments: [String] = CommandLine.arguments.count <= 1 ? [] : Array(CommandLine.arguments.dropFirst())
let outputDirectory = "resized"
createDir(dirName: outputDirectory)
let files = listAllFiles(atPath: ".", withExtension: ".jpg")
for filePath in files {
    var direction = ScaleDirection.down
    if (arguments.contains("-up")) { direction = .up }
    let width = getDimension(imagePath: filePath, dimension: .width, direction: direction)
    let height = getDimension(imagePath: filePath, dimension: .height, direction: direction)
    resizeImage(imagePath: filePath, width: width, height: height, outputFolder: outputDirectory)
}
