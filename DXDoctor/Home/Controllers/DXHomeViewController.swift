//
//  DXHomeViewController.swift
//  DXDoctor
//
//  Created by Jone on 15/12/5.
//  Copyright © 2015年 Jone. All rights reserved.
//

import UIKit

enum DXHomeTableViewType: Int{
    case Recommend = 0
    case Special
    case Other
}


let kRecomdCellIdentifier = "kRecomdCellIdentifier"
let kSpecialCellIdentifier = "kSpecialCellIdentifier"
let kOtherCellIdentifier = "kOtherCellIdentifier"


class DXHomeViewController: DXBaseViewController, DXSegmentViewDelegate, UIScrollViewDelegate, UITableViewDelegate, DXRecommendCellDelegate, DXSpecialCellDelegate, DXOtherCelDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    private let kRecommendCellHeight: CGFloat = 630
    private let kSpecialCellHeight: CGFloat = 224
    private let kOtherCellHeight: CGFloat = 89
    
    private let SEGMENT_HEI: CGFloat = 30.0;
    private var containerScrollView: UIScrollView!
    private var segmentView: DXSegmentView?
    private var topicItems: [String] = []
    
    var recommendDataSource: DXRecomTableDataSource!
    var specialDataSource: DXSpecialTableDataSource!
    var otherDataSource: DXOtherTableDataSoruce!
    
    var recommendDataList: [DXItemModel?]?
    
    override func loadView() {
        super.loadView()
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        view.backgroundColor = UIColor.whiteColor()
        title = "首页"
        
        setupNaviBar()
        setupSegmentView()
        setupScrollView()
        
        configDataSourceForTableView()
        setupTableViews()
        
        // simulate Loading animation
        simulateLoading()
        
        requestRecommend()
 
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.hideBottomHairline()
//        self.askDoctorView?.startAnimation()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.navigationBar.showBottomHairline()
    }
    
    // Mark: Request
    private func requestRecommend() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true;
            DXNetworkManager.shareManager.requestRecommendList { (items, error) in
                if ((error) != nil) { return }
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                self.recommendDataList = items
                self.collectionView.reloadData()
        }
    }

    // 初始化 TableView 数据源
    func configDataSourceForTableView() {
        recommendDataSource = DXRecomTableDataSource() // 不可使用 lazy
        recommendDataSource.cellDelegate = self
        
        specialDataSource   = DXSpecialTableDataSource()
        specialDataSource.cellDelegate = self
        
        otherDataSource     = DXOtherTableDataSoruce()
        otherDataSource.cellDelegate = self
    }
    
    // MARK: View
    // 设置导航栏
    func setupNaviBar() {
        let titleImageView = UIImageView.init(image: UIImage.init(named: "home_dxy_logo"))
        navigationItem.titleView = titleImageView;
        navigationItem.backBarButtonItem = UIBarButtonItem.init(title: "返回", style: .Plain, target: self, action: nil)
        setUpNavigationBar()
    }
    
    // 初始化选项栏
    func setupSegmentView() {
        topicItems = ["推荐", "专题", "真相", "慢病","一图读懂", "肿瘤" /*, "营养" */]
        let frame = CGRectMake(0, 64, view.bounds.size.width, SEGMENT_HEI)
        segmentView = DXSegmentView.init(titles: topicItems, iframe: frame);
        segmentView!.backgroundColor = UIColor.whiteColor()
        segmentView!.delegate = self
        view.addSubview(segmentView!)
    }
    
    // 初始化左右滚动内容视图
    func setupScrollView() {
        
        let originY = (segmentView?.height)! + (segmentView?.y)!
        containerScrollView = UIScrollView.init(frame: CGRectZero)
        containerScrollView.frame           = CGRectMake(0, originY, view.width, view.height - originY - 49)
        containerScrollView.contentSize     = CGSizeMake(CGFloat(topicItems.count) * view.width, (containerScrollView.height));
        containerScrollView.backgroundColor = DXSettingManager.manager.beigeWhiteColor
        containerScrollView.pagingEnabled   = true;
        containerScrollView.bounces         = false
        containerScrollView.delegate        = self;
        containerScrollView.showsVerticalScrollIndicator = false
        containerScrollView.showsHorizontalScrollIndicator = false
        view.addSubview(containerScrollView)
        
    }
    
    // Recommend CollectionView - First
    private var _collectionView: UICollectionView!
    private var collectionView: UICollectionView  {
        get {
            if (_collectionView != nil) {return _collectionView! }
            let layout = UICollectionViewFlowLayout()
            layout.minimumLineSpacing = 0.25
            layout.minimumInteritemSpacing = 0.5
            _collectionView = UICollectionView.init(frame: containerScrollView.bounds, collectionViewLayout: layout)
            _collectionView.dataSource = self // datasource class no effect
            _collectionView.delegate = self;
            _collectionView.backgroundColor = UIColor.redColor()
//            _collectionView.registerClass(DXRecomImageCell.self, forCellWithReuseIdentifier: "DXRecomImageCell")
            
            let recomImageCell = UINib.init(nibName: "DXRecomImageCell", bundle: nil)
            _collectionView.registerNib(recomImageCell, forCellWithReuseIdentifier: "DXRecomImageCell")
            
            let recomImageNoneCell = UINib.init(nibName: "DXRecomImageNoneCell", bundle: nil)
            _collectionView.registerNib(recomImageNoneCell, forCellWithReuseIdentifier: "DXRecomImageNoneCell")
            
            let recomSmallImageNoneCell = UINib.init(nibName: "DXRecomSmallImageNoneCell", bundle: nil)
            _collectionView.registerNib(recomSmallImageNoneCell, forCellWithReuseIdentifier: "DXRecomSmallImageNoneCell")
            
            return _collectionView;
        }
    }
    
    // Set Up Table views - Second ...
    func setupTableViews() {
        
        for index in 0 ..< topicItems.count {
            let tableView = createTableView(index: index)
            
            if let type = DXHomeTableViewType(rawValue: index) {
            
                switch type {
                    
                case .Recommend:
                    self.collectionView.frame = CGRectMake(0, 0, containerScrollView.width, containerScrollView.height)
                    containerScrollView.addSubview(self.collectionView)
                    
//                    tableView.dataSource = recommendDataSource
//                    tableView.registerNib(UINib.init(nibName: "DXRecommendCell", bundle: nil), forCellReuseIdentifier: kRecomdCellIdentifier)
                    
                    
                case .Special:
                    
                    tableView!.dataSource = specialDataSource
                    tableView!.registerNib(UINib.init(nibName: "DXSpecialCell", bundle: nil), forCellReuseIdentifier: kSpecialCellIdentifier)
                    
                default:
                    
                    tableView!.dataSource = otherDataSource
                    tableView!.registerNib(UINib.init(nibName: "DXOtherCell", bundle: nil), forCellReuseIdentifier: kOtherCellIdentifier)
                }
            }else {
                // 第四项
                tableView!.dataSource = otherDataSource
                tableView!.registerNib(UINib.init(nibName: "DXOtherCell", bundle: nil), forCellReuseIdentifier: kOtherCellIdentifier)

            }
        }
    }
    

    
    // Init table view
    func createTableView(index index: Int) -> UITableView? {
        if (index == 0) {
            return nil
        }
        
        
        let tableView = UITableView.init(frame: CGRectMake(CGFloat(index) * view.width, 0, containerScrollView.width, (containerScrollView.height)))
        tableView.delegate = self
        tableView.tag = index
        tableView.separatorStyle = .None
        tableView.backgroundColor = DXSettingManager.manager.beigeWhiteColor
        tableView.allowsSelection = false
        containerScrollView.addSubview(tableView)
        
        // 初始化下拉刷新控件
        let pullRefreshView = DXPullToRefresh.init(scrollView: tableView, hasNavigationBar: false)
        pullRefreshView.addRefreshingBlock({ () -> (Void) in
            
            // 下拉刷新操作
            //...
            
            let delayInSeconds: UInt64 = 2
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC * delayInSeconds));
            
            dispatch_after(popTime, dispatch_get_main_queue(), { () -> Void in
                pullRefreshView.stopRefreshing()
            })
        })
        
        
        let pullRefreshFooterView = DXPullToRefreshFooter.init(scrollView: tableView, hasNavigationBar: false)
        pullRefreshFooterView.addRefreshingBlock({ () -> (Void) in
            
            // 上拉刷新操作
            //...模拟数据
            
            let delayInSeconds: UInt64 = 2
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC * delayInSeconds));
            
            dispatch_after(popTime, dispatch_get_main_queue(), { () -> Void in
                pullRefreshFooterView.stopRefreshing()
                tableView.reloadData()
            })
        })
        
        return tableView
    }
    
    // MARK: DXAskdoctorViewDelegate
    override func askDoctorButtonItemOnTapped(sender: UIButton) {
        
        let askDoctorVC = DXAskDoctorViewController()
        askDoctorVC.hidesBottomBarWhenPushed = true
        
        self.navigationController?.pushViewController(askDoctorVC, animated: true)
    }
    
     // 模拟启动数据加载效果
    func simulateLoading() {
        
        self.showLoadingHUD()
        let delayInSeconds: UInt64 = 1
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC * delayInSeconds));
        
        dispatch_after(popTime, dispatch_get_main_queue(), { () -> Void in
            self.hideLoadingHUD(animation: true)
        })
    }
}


// MARK: UITableViewDelegate

extension DXHomeViewController {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if let tableViewType = DXHomeTableViewType(rawValue: tableView.tag) {
            
            switch tableViewType {
                
            case .Recommend:
                return kRecommendCellHeight
            case .Special:
                return kSpecialCellHeight
            default:
                return kOtherCellHeight
            }
        }else {
            return kOtherCellHeight
        }
    }

}

// MARK: Cell Delegate

extension DXHomeViewController {
    
    // Recommend
    func headerViewOnClick(cell: DXRecommendCell) {
        showLoadingWebView(cell)
    }
    
    func leftViewOnClick(cell: DXRecommendCell) {
        showLoadingWebView(cell)
    }
    
    func rightViewOnClick(cell: DXRecommendCell) {
        showLoadingWebView(cell)
    }
    
    func footerViewOnClick(cell: DXRecommendCell) {
        showLoadingWebView(cell)
    }
    
    // Special
    func specialCellOnClick(cell: DXSpecialCell) {
        showTestWebView()
    }
    
    // Other
    func otherCellOnClick(cell: DXOtherCell) {
        showTestWebView()
    }
    
    // Common
    func showLoadingWebView(cell: DXRecommendCell) {
        
        let mainStoryboard = UIStoryboard.init(name: "Main", bundle: nil)
        let recommHeaderVC = mainStoryboard.instantiateViewControllerWithIdentifier("DXWebViewController") as! DXWebViewController;
        
        recommHeaderVC.hidesBottomBarWhenPushed = true
        recommHeaderVC.contentURL = (cell.dataModel?.headerUrl)!
        self.navigationController?.pushViewController(recommHeaderVC, animated: true)
        
    }
    
    func showTestWebView() {
        let testVC = TestWebVeiwController()
        testVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(testVC, animated: true)
    }
}

// MARK: DXSegmentViewDelegate
extension DXHomeViewController {
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        guard scrollView == containerScrollView else {
            return
        }
        
        if (!scrollView.tracking) {
            let curPage: Int = Int(scrollView.contentOffset.x / view.width)
            segmentView?.topicItemTappedAtIndex(curPage)
        }
    }
    
    func segmentItemOnClickedAtIndex(index: Int) {
        containerScrollView.setContentOffset(CGPointMake(CGFloat(index) * view.width, 0), animated: true)
    }

}

// MARK: UICollectionView delegate and data source
extension DXHomeViewController {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let itemHeight:CGFloat = 210.0
        if let item = recommendDataList![indexPath.row] {
            switch item.showType {
            case .SmallImageNone:
                return CGSizeMake((collectionView.width-1)/2, itemHeight)
            default:
                return CGSizeMake(collectionView.width, itemHeight)
            }
        }else {
            return CGSizeZero
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print(indexPath.row)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (recommendDataList?.count) ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell!
        let indexItem = recommendDataList![indexPath.row] as DXItemModel!
            switch indexItem.showType {
            case .Image:
                cell = collectionView.dequeueReusableCellWithReuseIdentifier("DXRecomImageCell", forIndexPath: indexPath)
            case .ImageNone:
                cell = collectionView.dequeueReusableCellWithReuseIdentifier("DXRecomImageNoneCell", forIndexPath: indexPath)
            case .SmallImageNone:
                cell = collectionView.dequeueReusableCellWithReuseIdentifier("DXRecomSmallImageNoneCell", forIndexPath: indexPath)
            }
      
        cell.contentView.backgroundColor = UIColor.redColor()
        return cell
    }
}