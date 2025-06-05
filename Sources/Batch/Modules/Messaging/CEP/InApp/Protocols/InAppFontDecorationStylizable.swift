//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Generalize decoration style for ``InAppButtonView.Configuration.FontStyle`` and  ``InAppLabelView.Configuration.FontStyle``
protocol InAppFontDecorationStylizable {
    var fontDecoration: [InAppFontDecoration]? { get }
}
