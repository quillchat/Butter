import Foundation
import SnapKit
import UIKit

class ToastView: UIView {
  static let minimumWidth: CGFloat = 194
  static let height: CGFloat = 50

  private let contentView = UIView()
  private var visualEffectView: UIVisualEffectView!
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let activityIndicatorView = UIActivityIndicatorView(style: .medium)
  private let circularProgressView = CircularProgressView()
  private var tapGestureRecognizer: UITapGestureRecognizer!
  private var leadingItemStackView = UIStackView()

  var onTap: (() -> Void)?

  var onProgressFinished: (() -> Void)?

  init() {
    super.init(frame: .zero)
    doInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    doInit()
  }

  var toast: Toast? {
    didSet {
      titleLabel.text = toast?.title

      if let subtitle = toast?.subtitle {
        subtitleLabel.isHidden = false
        subtitleLabel.text = subtitle
      } else {
        subtitleLabel.isHidden = true
      }

      let appearance = toast?.appearance ?? .standard

      switch appearance {
      case .standard:
        visualEffectView.isHidden = false
        backgroundColor = .clear
        titleLabel.textColor = .label
        subtitleLabel.textColor = .secondaryLabel
      case .error:
        backgroundColor = .systemRed
        visualEffectView.isHidden = true
        titleLabel.textColor = .white
        subtitleLabel.textColor = .white
      }

      let style = toast?.style ?? .standard

      switch style {
      case .standard:
        activityIndicatorView.isHidden = true
        circularProgressView.isHidden = true
      case .indeterminate:
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
        circularProgressView.isHidden = true
      case let .progress(progress):
        circularProgressView.onFinished = { [weak self] in
          self?.onProgressFinished?()
        }

        activityIndicatorView.isHidden = true
        circularProgressView.isHidden = false
        circularProgressView.observedProgress = progress
      }
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = bounds.size.height / 2
    contentView.layer.cornerRadius = bounds.size.height / 2
  }

  @objc private func tapGestureRecognizerAction() {
    onTap?()
  }

  private func doInit() {
    backgroundColor = .clear

    layer.shadowRadius = 6
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOffset = CGSize(width: 0, height: 2)
    layer.shadowOpacity = 0.2

    titleLabel.font = .boldSystemFont(ofSize: 13)
    subtitleLabel.font = .systemFont(ofSize: 13)

    let stackView = UIStackView()

    stackView.spacing = 2
    stackView.axis = .vertical

    stackView.addArrangedSubview(titleLabel)
    stackView.addArrangedSubview(subtitleLabel)

    stackView.alignment = .center
    stackView.distribution = .fill

    visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))

    addSubview(contentView)

    contentView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    contentView.backgroundColor = .clear

    contentView.layer.masksToBounds = true

    contentView.addSubview(visualEffectView)
    contentView.addSubview(leadingItemStackView)
    contentView.addSubview(stackView)

    leadingItemStackView.addArrangedSubview(activityIndicatorView)
    leadingItemStackView.addArrangedSubview(circularProgressView)

    visualEffectView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    titleLabel.setContentCompressionResistancePriority(.defaultHigh - 1, for: .horizontal)
    subtitleLabel.setContentCompressionResistancePriority(.defaultHigh - 1, for: .horizontal)

    self.snp.makeConstraints { make in
      make.width.equalTo(Self.minimumWidth).priority(.medium)
      make.height.equalTo(Self.height)
    }

    stackView.snp.makeConstraints { make in
      make.top.greaterThanOrEqualToSuperview()
      make.bottom.lessThanOrEqualToSuperview()
      make.center.equalToSuperview()

      make.left.equalToSuperview().inset(Self.height / 2).priority(.medium)
      make.left.equalTo(leadingItemStackView.snp.right).inset(-8).priority(.high)
    }

    leadingItemStackView.snp.makeConstraints { make in
      make.center.equalTo(Self.height / 2)
    }

    titleLabel.textColor = .label
    subtitleLabel.textColor = .secondaryLabel

    contentView.isUserInteractionEnabled = false
    visualEffectView.isUserInteractionEnabled = false
    stackView.isUserInteractionEnabled = false

    tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerAction))

    addGestureRecognizer(tapGestureRecognizer)
  }
}
