import UIKit
import SpriteKit
import Social
import GameKit
import StoreKit

class GameViewController: UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    var product_id: String?

    override func viewDidLoad() {
        product_id = "PREMIUM"
        super.viewDidLoad()
        let defaults = NSUserDefaults.standardUserDefaults()
        if let options: [String:Bool] = defaults.dictionaryForKey("options") as? [String:Bool] {
            Options.option.setOptions(options)
        }
        let scene = MainMenuScene(size: CGSize(width: 2048, height: 1536))
        let skView = self.view as! SKView
        //skView.showsFPS = true
        //skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .AspectFill
        scene.viewController = self
        skView.presentScene(scene)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "shareAction:", name: "social", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "unlockPremium:", name: "premium", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "restore:", name: "restore", object: nil)

        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }

    func viewControllerForPresentingModalView() -> UIViewController {
        return self
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    func shareAction(notification: NSNotification) {
        let score = notification.userInfo!["score"] as! String
        let type = notification.userInfo!["type"] as! NSString
        if SLComposeViewController.isAvailableForServiceType(type as String) {
            let social = SLComposeViewController(forServiceType: type as String)
            var text = "I scored \(score) in Space Evaders! Can you beat that? https://appsto.re/us/lgcg5.i"
            if score == "-1" {
                text = "Check out the iPhone game Space Evaders! https://appsto.re/us/lgcg5.i"
            }
            social.setInitialText(text)
            self.presentViewController(social, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Accounts", message: "Please login to your social media account to share!", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "I will", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func openGC() {
        GCHelper.sharedInstance.showGameCenter(self, viewState: .Default)
    }

    func restore(notifaction: NSNotification) {
        print("Restoring purchase!", terminator: "")
        if (SKPaymentQueue.canMakePayments()) {
            SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
        }
    }
    
    func unlockPremium(notification: NSNotification) {
        if (SKPaymentQueue.canMakePayments()) {
            let productID = Set(arrayLiteral: self.product_id!)
            let productsRequest: SKProductsRequest = SKProductsRequest(productIdentifiers: productID)
            productsRequest.delegate = self
            productsRequest.start()
            print("Fetching Products")
        } else {
            print("Can't make purchases")
        }
    }

    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        let count: Int = response.products.count
        if (count > 0) {
            let validProduct: SKProduct = response.products[0] 
            if (validProduct.productIdentifier == self.product_id) {
                print(validProduct.localizedTitle)
                print(validProduct.localizedDescription)
                print(validProduct.price)
                buyProduct(validProduct)
            } else {
                print(validProduct.productIdentifier)
            }
        } else {
            print("nothing")
        }
    }


    func request(request: SKRequest, didFailWithError error: NSError) {
        print("Error Fetching product information")
    }

    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("Received Payment Transaction Response from Apple")

        for transaction: AnyObject in transactions {
            if let trans: SKPaymentTransaction = transaction as? SKPaymentTransaction {
                switch trans.transactionState {
                case .Purchased, .Restored:
                    print("Product Purchased")
                    SKPaymentQueue.defaultQueue().finishTransaction(transaction as! SKPaymentTransaction)
                    Options.option.set("premium", val: true)
                    break
                case .Failed:
                    print("Purchased Failed")
                    SKPaymentQueue.defaultQueue().finishTransaction(transaction as! SKPaymentTransaction)
                    break
                default:
                    break
                }
            }
        }
    }

    func buyProduct(product: SKProduct) {
        print("Sending the Payment Request to Apple")
        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }
}
