//
//  IndexedUniqueObject.swift
//  RealmDAO
//
//  Created by Brian Thomas on 7/4/21.
//

import Foundation

public class IndexedUniqueObject: UniqueObject {
    public dynamic var index: Int = -1
}

public extension RealmDAO where T: IndexedUniqueObject, T: UniqueStringKeyed {

    func defaultBackingCursor() -> IndexCursorObject {
        let cursorDAO = RealmDAO<IndexCursorObject>()
        return cursorDAO.lazyRecord(NSStringFromClass(T.self))
    }
    
    func backingCursor(collectionID: String) -> IndexCursorObject {
        let cursorDAO = RealmDAO<IndexCursorObject>()
        return cursorDAO.lazyRecord(collectionID)
    }

    // ERROR: SOMETHING IS WRONG HERE!! MAYBE RETURN IF UNIQUE OBJECT WAS FETCHED OR CREATED FRESHLY??
    // MAYBE SEND IN THE CURSOR SO THE BUILD FUNCTION INDEXES IT?
    func update(_ key: String, write: (T) -> ()) -> T {

        let object = lazyRecord(key)

        let cursorDAO = RealmDAO<IndexCursorObject>()
        let cursor = cursorDAO.lazyRecord(NSStringFromClass(T.self))

        let realm = backingRealm()
        let _ = try? realm.write {
            write(object)
            object.index = cursor.endIndex + 1
            object.lastUpdatedAt = NSDate() as Date
            realm.add(object, update: .all)
        }

        let _ = cursorDAO.update(cursor.uniqueKey) { innerCursor in
            if object.index > innerCursor.endIndex {
                innerCursor.endIndex = object.index
            }
        }

        return object
    }

    fileprivate func insert(_ items: [T]) -> Result<[T], RealmDAOError> {

        for item in items {
            if item.index != -1 {
                return Result.failure(.insertingOldObject)
            }
        }

        let cursorDAO = RealmDAO<IndexCursorObject>()
        let cursor = cursorDAO.lazyRecord(NSStringFromClass(T.self))
        var nextIndex: Int = cursor.endIndex

        for item in items {
            item.index = nextIndex + 1
            nextIndex = nextIndex + 1
        }


        let realm = backingRealm()
        let _ = try? realm.write {
            realm.add(items, update: .all)
        }

        let _ = cursorDAO.update(cursor.uniqueKey) { (updatingCursor) in
            updatingCursor.endIndex = nextIndex
        }

        return Result.success(items)
    }

    func recent(_ count: Int) -> [T] {
        let cursorDAO = RealmDAO<IndexCursorObject>()
        let cursor = cursorDAO.lazyRecord(NSStringFromClass(T.self))

        let finalIndex = cursor.endIndex

        if finalIndex <= count {
            return self.all()
        } else {
            let fromIndex = finalIndex - count
            return self.fetch({ (record) -> Bool in
                return record.index > fromIndex
            })
        }
    }

    internal func segmentSequence(_ identifer: String, update updateFunc: (RecordsSegmentSequenceType) -> ()) {
        let segmentSequenceDAO = RealmDAO<RecordsSegmentSequence>()
        let _ = segmentSequenceDAO.update("\(NSStringFromClass(T.self))\(identifer))".lowercased()) { sequence in
            updateFunc(RecordsSegmentSequenceInWriteBlock(sequence: sequence))
        }
    }

}
