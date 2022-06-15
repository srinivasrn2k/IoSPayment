import UIKit

protocol SelectionButtonTableViewCellDelegate: AnyObject {
    func buttonIsPressed(tag: Int)
}

final class SelectionButtonTableViewCell: UITableViewCell {
    weak var delegate: SelectionButtonTableViewCellDelegate?

    private lazy var mainView: SelectionButtonView? = {
        let view = SelectionButtonView()
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        self.setupViewsInOrder()
    }

    func update(style: CellButtonStyle, tag: Int) {
        self.tag = tag
        mainView?.update(style: style)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SelectionButtonTableViewCell {

    private func setupViewsInOrder() {
        guard let mainView = mainView else { return }
        contentView.addSubview(mainView)
        NSLayoutConstraint.activate([
            mainView.topAnchor.constraint(
                equalTo: contentView.topAnchor),
            mainView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor),
            mainView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor),
            mainView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -24)
        ])
    }
}

extension SelectionButtonTableViewCell: SelectionButtonViewDelegate {
    func buttonIsPressed() {
        delegate?.buttonIsPressed(tag: tag)
    }
}