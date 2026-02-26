//
//  FullscreenViewer.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-15.
//

import SwiftUI
import Nuke
import NukeUI
import NukeVideo

private struct FullscreenViewer: View {
  let asset: any RemoteAsset
  let request: ImageRequest
  @Environment(\.dismiss) var dismiss
  @Environment(\.onUseGeneration) var onUseGeneration
  @State private var showingShareSheet = false

  init(asset: any RemoteAsset) {
    self.asset = asset
    self.request = ImageRequest(
      url: URL(string: asset.assetUrl ?? asset.imageUrl ?? ""),
      processors: [ImageProcessors.Resize.fullWidth]
    )
  }

  var body: some View {
    if let url = request.url, url.pathExtension == "mp4" {
      GeometryReader { geometry in
        VideoPlayer(url: request.url)
          .frame(width: geometry.size.width, height: geometry.size.height - 300)
          .clipped()
          .clipShape(.rect(cornerRadius: 30))
          .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 2)
      }
    } else {
      LazyImage(request: request) { state in
        VStack(spacing: 0) {
          if let image = state.image {
            GeometryReader { geometry in
              VStack(spacing: 20) {
                image
                  .resizable()
                  .scaledToFill()
                  .frame(width: geometry.size.width, height: geometry.size.height - 300)
                  .clipped()
                  .clipShape(.rect(cornerRadius: 30))
                  .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 2)

                switch asset {
                case let generation as Generation:
                  AssetActionButtons(
                    onUseGeneration: {
                      onUseGeneration(generation, image)
                      dismiss()
                    },
                    onShare: {
                      showingShareSheet = true
                    },
                    onSaveToPhotos: {
                      UIImageWriteToSavedPhotosAlbum(request.cachedOriginal, nil, nil, nil)
                    })
                  .sheet(isPresented: $showingShareSheet) {
                    ShareSheet(items: [request.cachedOriginal])
                  }
                default:
                  EmptyView()
                }
              }
              .navigationBarBackButtonHidden(true)
              .onTapGesture {
                dismiss()
              }
            }
          } else if state.isLoading {
            VStack {
              Spacer()
              ProgressView(value: state.progress.fraction)
                .frame(maxWidth: .infinity)
              Spacer()
            }
            .aspectRatio(1.2, contentMode: .fit)
            .frame(maxWidth: .infinity)
          } else if let error = state.error {
            Text("Error: \(error.localizedDescription)")
          }
        }
        .padding(.horizontal, 12)
      }
    }
  }
}

@Observable class FullscreenViewerState {
  var currentAsset: (any RemoteAsset)? = nil
  let namespace: Namespace.ID

  init(namespace: Namespace.ID) {
    self.namespace = namespace
  }
}

struct FullscreenViewerContainer<Content: View>: View {
  @ViewBuilder let content: (FullscreenViewerState) -> Content
  @Namespace private var namespace
  @State private var state: FullscreenViewerState?

  var body: some View {
    Group {
      if let state {
        content(state)
          .modifier(FullscreenViewerModifier(
            currentAsset: Binding(
              get: { state.currentAsset },
              set: { state.currentAsset = $0 }
            ),
            namespace: namespace
          ))
      } else {
        Color.clear
          .onAppear {
            state = FullscreenViewerState(namespace: namespace)
          }
      }
    }
  }
}

private struct FullscreenViewerModifier: ViewModifier {
  @Binding var currentAsset: (any RemoteAsset)?
  var namespace: Namespace.ID

  func body(content: Content) -> some View {
    content
      .fullScreenCover(
        isPresented: Binding(
          get: { currentAsset != nil },
          set: { if !$0 { currentAsset = nil } }
        )
      ) {
        if let asset = currentAsset {
          FullscreenViewer(asset: asset)
            .navigationTransition(.zoom(sourceID: asset.id, in: namespace))
        }
      }
  }
}

extension View {
  func zoomable(asset: any RemoteAsset, state: FullscreenViewerState) -> some View {
    return self
      .matchedGeometryEffect(id: asset.id, in: state.namespace)
      .matchedTransitionSource(id: asset.id, in: state.namespace)
      .onTapGesture {
        state.currentAsset = asset
      }
  }
}

struct MockAsset: RemoteAsset {
  let id: String
  let imageUrl: String?
  let assetUrl: String?
}

#Preview {
  let namespace = Namespace().wrappedValue

  let state = FullscreenViewerState(namespace: namespace)
  let mockAsset = MockAsset(id: "1", imageUrl: "https://images.unsplash.com/photo-1682685797366-715d29e33f9d?w=800", assetUrl: "https://images.unsplash.com/photo-1682685797366-715d29e33f9d?w=800")
  let mockAsset2 = MockAsset(id: "2", imageUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1234&q=80",
                             assetUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1234&q=80")
  let mockVideo = MockAsset(id: "1", imageUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1234&q=80", assetUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")

  FullscreenViewerContainer { state in
    AsyncImage(url: URL(string: mockVideo.imageUrl!)!) { image in
      image
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .zoomable(asset: mockVideo, state: state)
    } placeholder: {
      EmptyView()
    }
  }
}
