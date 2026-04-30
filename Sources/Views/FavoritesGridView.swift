import SwiftUI

struct FavoritesGridView: View {
    @Binding var favorites: [String]
    var onSelect: (String) -> Void
    
    let columns = [GridItem(.adaptive(minimum: 140, maximum: 160), spacing: 20)]
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.1).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 30) {
                    Text("Favorites")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 60)
                    
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(favorites, id: \.self) { favUrl in
                            Button(action: { onSelect(favUrl) }) {
                                VStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.08))
                                            .frame(width: 80, height: 80)
                                        
                                        AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?sz=128&domain_url=\(favUrl)")) { image in
                                            image.resizable().aspectRatio(contentMode: .fit)
                                        } placeholder: { Color.gray.opacity(0.3) }
                                        .frame(width: 48, height: 48)
                                        .cornerRadius(8)
                                    }
                                    
                                    VStack(spacing: 2) {
                                        let titleParts = FavoritesStore.fallbackTitle(for: favUrl).components(separatedBy: " - ")
                                        Text(titleParts[0])
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.9))
                                            .lineLimit(1)
                                        
                                        if titleParts.count > 1 {
                                            Text(titleParts[1])
                                                .font(.system(size: 11))
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 40)
                }
            }
        }
    }
}
