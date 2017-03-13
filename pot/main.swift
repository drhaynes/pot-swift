#!/usr/bin/swift

//
//  main.swift
//  pot
//
//  Tool to resize images to the nearest power of two.
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


let arguments: [String] = CommandLine.arguments.count <= 1 ? [] : Array(CommandLine.arguments.dropFirst())

if let path = arguments.first {
    let width = getDimension(imagePath: path, dimension: .width, direction: .up)
    let height = getDimension(imagePath: path, dimension: .height, direction: .up)
    print(width)
    print(height)
} else {
    print("Usage: pot [path to image]")
}

