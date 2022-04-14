//
//  PublishingDAO.swift
//  RealmDAO
//
//  Created by Brian Thomas on 4/14/22.
//

import Foundation
import Combine
import RealmSwift

private var realmGenerator: (() -> Realm)! = .none

private func defaultRealm() -> Realm {
    return realmGenerator()
}

public class CombineDAO<T, S, E: Error> where T: UniqueObject {
    
    public var sync: CurrentValueSubject<DAOResult<[S], E>, Never> = .init(DAOResult<[S], E>.idle)
    public var results: CurrentValueSubject<DAOResult<[S], E>, Never> = .init(DAOResult<[S], E>.idle)
    public var actions = PassthroughSubject<DAOEvent<T>, Never>()
    public var events = PassthroughSubject<DAOEvent<S>, Never>()
    
    private var filter: ((T) -> Bool)?
    private var sort: ((_ lhs: T, _ rhs:T) -> Bool)?
    private var realmMap: (T) -> S
    
    private let work = DispatchQueue.global(qos: .background)
    private let main = DispatchQueue.main
    
    public static func configure(_ generator: @escaping () -> Realm) {
        realmGenerator = generator
    }
    
    public init(map: @escaping (T) -> S) {
        realmMap = map
    }
    
    public func refresh() {
        work.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.loading(action: DAOEvent<T>.refresh)
            
            let all: [T] = defaultRealm()
                .objects(T.self)
                .map { return $0 }
            let mapped = all.map(self.realmMap)
            self.results.value = .success(mapped)
            self.events.send(.refresh)
        }
    }
    
    public func syncResults() {
        sync.value = results.value
    }
    
}



// Helpers
private extension CombineDAO {
    func loading(action: DAOEvent<T>) {
        self.main.sync { [weak self] in
            self?.results.value = .loading
            self?.actions.send(action)
        }
    }
    
    func innerRefreshResults(realm: Realm) {
        var all: [T] = realm
            .objects(T.self)
            .map { return $0 }
        
        if let hadFilter = filter {
            all = all.filter(hadFilter)
        }
        if let hadSort = sort {
            all = all.sorted(by: hadSort)
        }
        
        let allMapped = all.map(self.realmMap)
        self.results.value = .success(allMapped)
    }
    
    func resolve(future: @escaping (Result<[S], RealmDAOError>) -> Void, event: DAOEvent<S>, items: [S]) {
        self.main.async { [weak self] in
            future(.success(items))
            self?.events.send(event)
        }
    }
    
    func resolve(future: @escaping (Result<S, RealmDAOError>) -> Void, event: DAOEvent<S>, item: S) {
        self.main.async { [weak self] in
            future(.success(item))
            self?.events.send(event)
        }
    }
}




// Sort and Filter
public extension CombineDAO {
    
    func applySort(sort: @escaping (_ lhs: T, _ rhs:T) -> Bool) {
        self.apply(filter: self.filter, sort: sort)
    }
    
    func applyFilter(filter: @escaping (T) -> Bool) {
        self.apply(filter: filter, sort: self.sort)
    }
    
    func apply(filter: ((T) -> Bool)?, sort: ((_ lhs: T, _ rhs:T) -> Bool)?) {
        self.filter = filter
        self.sort = sort
        innerRefreshResults(realm: defaultRealm())
    }
    
}




// Save
public extension CombineDAO {
    
    func save(_ object: T) -> AnyPublisher<S, Error> {
        Future<S, RealmDAOError> { [weak self] resolve in
            guard let self = self else {
                resolve(.failure(.unavailable))
                return
            }
            self.work.async { [weak self] in
                guard let self = self else {
                    resolve(.failure(.unavailable))
                    return
                }
                
                self.loading(action: .save([object]))

                let realm = defaultRealm()
                try! realm.write {
                    realm.add(object, update: .all)
                }
                let mapped = self.realmMap(object)
                
                self.innerRefreshResults(realm: realm)
                self.resolve(future: resolve, event: .save([mapped]), item: mapped)
            }
        }
        .eraseToError()
    }
    
    func saveBulk(_ objects: [T]) -> AnyPublisher<[S], Error> {
        Future<[S], RealmDAOError> { [weak self] resolve in
            guard let self = self else {
                resolve(.failure(.unavailable))
                return
            }
            self.work.async { [weak self] in
                guard let self = self else {
                    resolve(.failure(.unavailable))
                    return
                }

                self.loading(action: .save(objects))

                let realm = defaultRealm()
                try! realm.write {
                    realm.add(objects, update: .all)
                }
                let savedItems = objects.map { current in
                    self.realmMap(current)
                }
                
                self.innerRefreshResults(realm: realm)
                self.resolve(future: resolve, event: .save(savedItems), items: savedItems)
            }
        }
        .eraseToError()
    }
    
}




// Delete
public extension CombineDAO {
    func delete(_ object: T) -> AnyPublisher<S, Error> {
        Future<S, RealmDAOError> { [weak self] resolve in
            guard let self = self else {
                resolve(.failure(.unavailable))
                return
            }
            self.work.async { [weak self] in
                guard let self = self else {
                    resolve(.failure(.unavailable))
                    return
                }
                
                self.loading(action: .delete([object]))
                
                let realm = defaultRealm()
                try! realm.write {
                    realm.delete(object)
                }
                let deletedItem = self.realmMap(object)
                
                self.innerRefreshResults(realm: realm)
                self.resolve(future: resolve, event: .delete([deletedItem]), item: deletedItem)
            }
        }
        .eraseToError()
    }
    
    func delete(_ objects: [T]) -> AnyPublisher<[S], Error> {
        Future<[S], RealmDAOError> { [weak self] resolve in
            guard let self = self else {
                resolve(.failure(.unavailable))
                return
            }
            self.work.async { [weak self] in
                guard let self = self else {
                    resolve(.failure(.unavailable))
                    return
                }
                
                self.loading(action: .delete(objects))
                
                let realm = defaultRealm()
                try! realm.write {
                    realm.delete(objects)
                }
                let deletedItems = objects.map { current in
                    self.realmMap(current)
                }
                
                self.innerRefreshResults(realm: realm)
                self.resolve(future: resolve, event: .delete(deletedItems), items: deletedItems)
            }
        }
        .eraseToError()
    }
}


