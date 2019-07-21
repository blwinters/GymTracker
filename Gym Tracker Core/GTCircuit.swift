//
//  GTCircuit.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//
//

import Foundation
import CoreData

@objc(GTCircuit)
final public class GTCircuit: GTExercise, ExerciseCollection {
	
	override class var objectType: String {
		return "GTCircuit"
	}
	
	public static let collectionType = GTLocalizedString("CIRCUIT", comment: "Circuit")
	
	@NSManaged public private(set) var exercises: Set<GTSetsExercise>
	
	override class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> GTCircuit? {
		let req = NSFetchRequest<GTCircuit>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return dataManager.executeFetchRequest(req)?.first
	}
	
	public override var title: String {
		return Self.collectionType
	}
	
	public override var summary: String {
		return exerciseList.lazy.map { $0.title }.joined(separator: ", ")
	}
	
	override public var isValid: Bool {
		return workout != nil && isSubtreeValid
	}
	
	override var isSubtreeValid: Bool {
		return exercises.count > 1 && exercises.reduce(true) { $0 && $1.isValid } && exercisesError.isEmpty
	}
	
	public override var isPurgeableToValid: Bool {
		return false
	}
	
	public override var shouldBePurged: Bool {
		return exercises.isEmpty
	}
	
	override public var parentLevel: CompositeWorkoutLevel? {
		return workout
	}
	
	override public var subtreeNodes: Set<GTDataObject> {
		return Set(exercises.flatMap { $0.subtreeNodes } + [self])
	}
	
	public override func purge(onlySettings: Bool) -> [GTDataObject] {
		return exercises.reduce([]) { $0 + $1.purge(onlySettings: onlySettings) }
	}

	public override func removePurgeable() -> [GTDataObject] {
		var res = [GTDataObject]()
		for e in exercises {
			if e.shouldBePurged {
				res.append(e)
				self.remove(part: e)
			} else {
				res.append(contentsOf: e.removePurgeable())
			}
		}
		
		recalculatePartsOrder()
		return res
	}
	
	/// Whether or not the exercises of this circuit are valid inside of it.
	///
	/// An exercise has its index in `exerciseList` included if it has not the same number of sets as the most frequent sets count in the circuit.
	public var exercisesError: [Int] {
		return GTCircuit.invalidIndices(for: exerciseList.map { $0.setsCount })
	}
	
	class func invalidIndices(for setsCount: [Int?], mode m: Int?? = nil) -> [Int] {
		let mode = m ?? setsCount.mode
		return zip(setsCount, 0 ..< setsCount.count).filter { $0.0 == nil || $0.0 != mode }.map { $0.1 }
	}
	
	// MARK: - Exercises handling
	
	public var exerciseList: [GTSetsExercise] {
		return Array(exercises).sorted { $0.order < $1.order }
	}
	
	public func add(parts: GTSetsExercise...) {
		for se in parts {
			se.order = Int32(self.exercises.count)
			se.set(circuit: self)
		}
	}
	
	public func remove(part se: GTSetsExercise) {
		exercises.remove(se)
		recalculatePartsOrder()
	}
	
}
