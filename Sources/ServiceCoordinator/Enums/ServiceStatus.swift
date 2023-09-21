//
//  ServiceStatus.swift
//  
//
//  Created by Maximiliano Ovando Ramírez on 20/09/23.
//

/// Enum representing the status of a service operation.
///
/// This generic enum is used to encapsulate the outcome of a service operation, such as a network request.
///
/// - success: Indicates a successful operation with associated data.
/// - failed: Indicates a failed operation with an associated error.
/// - information: Indicates an informational status with an associated code.
public enum ServiceStatus<T> {
    /// Indicates a successful operation with associated data.
    case success(data: T)
    
    /// Indicates a failed operation with an associated error.
    case failed(error: Error)
    
    /// Indicates an informational status with an associated code.
    case information(code: Int)
}

