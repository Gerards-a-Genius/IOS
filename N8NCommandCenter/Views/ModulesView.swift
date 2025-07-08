//
//  ModulesView.swift
//  N8NCommandCenter
//
//  Workflow modules management view
//

import SwiftUI

struct ModulesView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.primaryBlue)
                
                Text("Workflow Modules")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Custom workflow modules will be available here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Coming in Phase 3")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .navigationTitle("Modules")
        }
    }
}

// MARK: - Preview
struct ModulesView_Previews: PreviewProvider {
    static var previews: some View {
        ModulesView()
    }
}