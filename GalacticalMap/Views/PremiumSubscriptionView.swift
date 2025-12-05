
import SwiftUI

struct PremiumSubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("isSubscribed") private var isSubscribed = false
    @State private var selectedPlan: SubscriptionPlan = .yearly
    var isForced: Bool = false
    
    enum SubscriptionPlan: String, CaseIterable, Identifiable {
        case monthly
        case yearly
        case lifetime
        
        var id: String { self.rawValue }
        
        var title: String {
            switch self {
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            case .lifetime: return "Lifetime"
            }
        }
        
        var price: String {
            switch self {
            case .monthly: return "$9.99"
            case .yearly: return "$99.99"
            case .lifetime: return "$199.99"
            }
        }
        
        var period: String {
            switch self {
            case .monthly: return "/ month"
            case .yearly: return "/ year"
            case .lifetime: return "one-time"
            }
        }
        
        var badge: String? {
            switch self {
            case .yearly: return "BEST VALUE"
            case .lifetime: return "MOST POPULAR"
            default: return nil
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Space dust effect
            Circle()
                .fill(Color.purple.opacity(0.2))
                .blur(radius: 60)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Color.blue.opacity(0.2))
                .blur(radius: 60)
                .offset(x: 100, y: 200)
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Spacer()
                    if !isForced {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal)
                
                // Title & Description
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                        .padding(.bottom, 4)
                    
                    Text("Unlock Premium")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(isForced ? "Your free trial has ended. Please subscribe to continue using the app." : "Get unlimited access to all features including live satellite tracking, AR sky view, and advanced astronomy tools.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(isForced ? .red : .gray)
                        .padding(.horizontal, 24)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                }
                
                // Plans
                VStack(spacing: 12) {
                    ForEach(SubscriptionPlan.allCases) { plan in
                        PlanOptionView(plan: plan, isSelected: selectedPlan == plan)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedPlan = plan
                                }
                            }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Subscribe Button
                Button {
                    // Simulate successful subscription
                    isSubscribed = true
                    dismiss()
                } label: {
                    Text("Subscribe Now")
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(14)
                        .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
                
                // Footer
                HStack(spacing: 20) {
                    Button("Terms of Service") {}
                    Button("Restore Purchase") {}
                    Button("Privacy Policy") {}
                }
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.bottom)
            }
        }
        .interactiveDismissDisabled(isForced)
    }
}

struct PlanOptionView: View {
    let plan: PremiumSubscriptionView.SubscriptionPlan
    let isSelected: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .gray)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(plan.price)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(plan.period)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                Circle()
                    .strokeBorder(isSelected ? Color.yellow : Color.gray.opacity(0.5), lineWidth: 1.5)
                    .background(Circle().fill(isSelected ? Color.yellow : Color.clear))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(isSelected ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
            )
            
            if let badge = plan.badge {
                Text(badge)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.yellow)
                    .cornerRadius(6)
                    .offset(x: -8, y: -8)
            }
        }
    }
}

#Preview {
    PremiumSubscriptionView()
}
