import UIKit

final class TaskListViewController: UIViewController {
    private let statusBanner = StatusBannerView()
    private var collectionView: UICollectionView!
    private var tasks: [TaskDTO] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Công việc"
        view.backgroundColor = AppTheme.Colors.background
        configureNavigation()
        configureLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTasks()
    }

    private func configureNavigation() {
        navigationItem.rightBarButtonItem = UIFactory.iconButton(systemName: "plus", target: self, action: #selector(showCreateTask))
    }

    private func configureLayout() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = AppTheme.Spacing.md
        layout.sectionInset = UIEdgeInsets(top: AppTheme.Spacing.md, left: AppTheme.Spacing.md, bottom: AppTheme.Spacing.lg, right: AppTheme.Spacing.md)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = AppTheme.Colors.background
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TaskListCell.self, forCellWithReuseIdentifier: TaskListCell.reuseIdentifier)

        view.addSubview(statusBanner)
        view.addSubview(collectionView)
        statusBanner.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            statusBanner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: AppTheme.Spacing.md),
            statusBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.md),
            statusBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.md),
            collectionView.topAnchor.constraint(equalTo: statusBanner.bottomAnchor, constant: AppTheme.Spacing.sm),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadTasks() {
        statusBanner.hide()
        APIClient.shared.fetchTasks { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                self.tasks = response.tasks.filter { $0.isCurrentTask }
                self.collectionView.reloadData()
                if self.tasks.isEmpty {
                    self.statusBanner.show(message: "Chưa có công việc hiện tại.", isError: false)
                }
            case .failure(let error):
                self.statusBanner.show(message: error.localizedDescription)
            }
        }
    }

    @objc private func showCreateTask() {
        let controller = TaskFormViewController(mode: .create)
        controller.onSave = { [weak self] in self?.loadTasks() }
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension TaskListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tasks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TaskListCell.reuseIdentifier, for: indexPath) as! TaskListCell
        cell.configure(with: tasks[indexPath.item])
        return cell
    }
}

extension TaskListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let controller = TaskDetailViewController(task: tasks[indexPath.item], allowsEditing: true)
        controller.onTaskChanged = { [weak self] in self?.loadTasks() }
        navigationController?.pushViewController(controller, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.bounds.width - AppTheme.Spacing.md * 2, height: 92)
    }
}
