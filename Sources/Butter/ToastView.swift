import Foundation
import UIKit

class ToastView: UIView {
  static let minimumWidth: CGFloat = 194
  static let height: CGFloat = 50

  /// The width and height of the image.
  static let imageSize: CGFloat = 24

  private let contentView = UIView()
  private var visualEffectView: UIVisualEffectView!
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let activityIndicatorView = UIActivityIndicatorView(style: .medium)
  private let circularProgressView = CircularProgressView()
  private let imageView = UIImageView()
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
        imageView.isHidden = true
      case .indeterminate:
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
        circularProgressView.isHidden = true
        imageView.isHidden = true
      case let .progress(progress, tintColor):
        circularProgressView.tintColor = tintColor
        circularProgressView.onFinished = { [weak self] in
          self?.onProgressFinished?()
        }

        activityIndicatorView.isHidden = true
        circularProgressView.isHidden = false
        circularProgressView.observedProgress = progress
        imageView.isHidden = true
      case let .image(image, shouldMaskToCircle):
        activityIndicatorView.isHidden = true
        circularProgressView.isHidden = true
        imageView.isHidden = false

        imageView.image = image
        imageView.layer.cornerRadius = shouldMaskToCircle ? Self.imageSize / 2.0 : 0
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

    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.constrainEdgesEqualToSuperview()

    contentView.backgroundColor = .clear

    contentView.layer.masksToBounds = true

    contentView.addSubview(visualEffectView)
    contentView.addSubview(leadingItemStackView)
    contentView.addSubview(stackView)

    leadingItemStackView.addArrangedSubview(activityIndicatorView)
    leadingItemStackView.addArrangedSubview(circularProgressView)
    leadingItemStackView.addArrangedSubview(imageView)

    visualEffectView.translatesAutoresizingMaskIntoConstraints = false
    visualEffectView.constrainEdgesEqualToSuperview()

    titleLabel.setContentCompressionResistancePriority(.defaultHigh - 1, for: .horizontal)
    subtitleLabel.setContentCompressionResistancePriority(.defaultHigh - 1, for: .horizontal)

    translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      widthAnchor.constraint(equalToConstant: Self.minimumWidth).priority(.init(500)),
      heightAnchor.constraint(equalToConstant: Self.height)
    ])

    stackView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor),
      stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
      stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: Self.height / 2).priority(.init(500)),
      stackView.leftAnchor.constraint(equalTo: leadingItemStackView.rightAnchor, constant: 8).priority(.defaultHigh)
    ])

    leadingItemStackView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      leadingItemStackView.centerXAnchor.constraint(equalTo: contentView.leftAnchor, constant: Self.height / 2),
      leadingItemStackView.centerYAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.height / 2)
    ])

    NSLayoutConstraint.activate([
      imageView.widthAnchor.constraint(equalToConstant: Self.imageSize),
      imageView.heightAnchor.constraint(equalToConstant: Self.imageSize)
    ])

    titleLabel.textColor = .label
    subtitleLabel.textColor = .secondaryLabel

    contentView.isUserInteractionEnabled = false
    visualEffectView.isUserInteractionEnabled = false
    stackView.isUserInteractionEnabled = false

    tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerAction))

    addGestureRecognizer(tapGestureRecognizer)
  }
}
