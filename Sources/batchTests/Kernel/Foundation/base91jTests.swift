//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation
import XCTest

class base91jTests: XCTestCase {
    let simpleCase: String = "ceciestuntest❤️"
    let simpleCaseEncoded: String = "OPWfd,DZ7U)/Tm{oG_~[DoOD"

    let complexJSON: String =
        "{\"id\":\"is_it_usefull_for_tracking_or_should_we_drop\",\"root\":{\"isVertical\":true,\"children\":[{\"image\":{\"id\":\"IMG_1\",\"aspect\":\"ASPECT_RATIO_FIT\"}},{\"text\":{\"id\":\"TXT_1\",\"fontSize\":\"FONT_SIZE_LARGE\",\"textAlign\":\"TEXT_ALIGN_CENTER\",\"padding\":[4]}},{\"text\":{\"id\":\"TXT_2\",\"textAlign\":\"TEXT_ALIGN_JUSTIFY\",\"margin\":[10,0,10,0],\"padding\":[4]}},{\"container\":{\"ratios\":[0.5,0.5],\"children\":[{\"button\":{\"id\":\"BTN_1\",\"borderRadius\":[4],\"padding\":[4],\"backgroundColor\":[\"#FFFFFF00\",\"#00000000\"],\"fontSize\":\"FONT_SIZE_SMALL\"}},{\"button\":{\"id\":\"BTN_2\",\"borderRadius\":[4],\"padding\":[4],\"backgroundColor\":[\"#FFFFFF00\",\"#00000000\"],\"fontSize\":\"FONT_SIZE_SMALL\"}}]}}]},\"urls\":{\"IMG_1\":\"https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png\"},\"htmlTexts\":{\"TXT_1\":\"<span data-color=\'#CC000000\' data-color-dark=\'#CCFFFF00\' data-b>This is a title</span>\",\"TXT_2\":\"<span data-color=\'#00000000\' data-color-dark=\'#FFFFFF00\' data-b>Lorem ipsum dolor ♥️ sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.</span>\",\"BTN_1\":\"<span data-color=\'#CC000000\' data-color-dark=\'#CCFFFF00\' data-b>Nope</span>\",\"BTN_2\":\"<span data-color=\'#CC000000\' data-color-dark=\'#CCFFFF00\' data-b>Yes, I want to subscribe</span>\"},\"actions\":{\"BTN_1\":{\"batchAction\":\"ACTION_TYPE_DISMISS\"},\"BTN_2\":{\"batchAction\":\"ACTION_TYPE_CLIPBOARD\",\"payload\":\"{\'t\':\'PROMO_CODE\'}\"}},\"kind\":\"KIND_FULL_SCREEN\",\"closeOptions\":[{\"delay\":{\"delay\":5,\"backgroundColor\":[\"#00000000\",\"#FFFFFF00\"]},\"cross\":{\"backgroundColor\":[\"#00000000\",\"#FFFFFF00\"],\"color\":[\"#FFFFFF00\",\"#00000000\"]}}]}"
    let complexJSONEncoded: String =
        "~GWJRYwMt#Vs6xzh(2_1z][*+Q9&.^^oGEX<M:/p,9`+{l&kb8wJI()e+Q@+[EKMKGy=h>/NV3twimke)z(g^*7*EGq/a99jKG%IM:@YL%X%BYHg~G)fv)keEGc^*Mcjv/uZg2|`9IH!)M0obP(IVYwMq4|W/k5d!z(F0zM{i5wc+5Lso<CDg,NZFGc^*Mcjv/ADL!W{9IH!B*Pnr5<dI{rNUK5IA,6dt2pz+w3*rLbKyZvP64^I^[{)x#Y%BYDM'O*HE({)[5HU{lgYL5JzMYUM&$Pz8P;m*G5.:kR;FWV^vu9j15Dw8{jz7R+[uuFfM}nxDfXX<R//@vGlvoDwGY~dvPGs@v+ZPoj1~7eY[MyjvuBMBE0=L:9NV3m*Lv`QcwVE@hz*AGDvmxFl]UDwO$a:E(0!^b>i3o(gK:yeKU+[^bMoe5,<Q[B5DQ}$fv`Q17RIDYRvwSVza9:mv/w;WYaerU)&gboU~GWJRYwM5LOUoPCMKGN<r@eeKU?u8Pap[G5.:kz*AGDvmxFl]UDwO$a:.HBwDm*l+zbg!=HTzT$&wboU5GJwmxbjgM](4YvP:IVE[hFBrI,(*52PXR/2@[q0w&iwFZ8YXo_:56?5S5Wb7O:aqGuhaf|NY!,/@^;mv/<3`/pNUKADU,uhQG[wB*#N9!@+?ObjV8O3@ouYjQGwQQbjmaU=RYP#T2k!AYWiDgJ2i>f[8!r&w^Vov/C1$YbjgM;IID{QMiv+=hFBrI,(KCCM,iBwf>_Y!7O]|aoUXR~za7}S[MwH{lRbri%zA}[;E(rpvyBM_zE=UYP#Gz!S][gRv/AD?[yCbUn&<@Aq#o1<h>,*;RsxO99Q&lH<c,_{XREv>xFl]U!,f>;pG$o!8^PnfwH>z.<{QS60w^hkn}W<X<#N,Q6=SCTU/L[2[>/pFz0!tB`o|i_d9_nTFGc^vuFfM}fx@oY)XUDv=ETje5Gf)*|*1Tn{rj3X)tVE[hFB[G:yaxYi`I.Jh>7;4!>+~8.N;I_ymxbjsIL3muWiIEAx?r>ux#6timlLGB%g?[ue53',RQ:mcG[wP7oY*QJwFZNVZu01/W;Hr%;#L^Lm>z^.%YFBrI,(KC{Qp'7P_o6lV<X<#N'H}u,m2V?IQzmxbjgM,(%BTje5GfE*@)zT90/E}k!2;g/W2{G$`+_XK2Bs+^[WP1qU2uG9_ou'L^;meP(Ig,!eLU2u8Pwn32Wf7=YC,RY6LycLeP;Im+oC.!L;e9QnJB%g`<>{KU=53mFlmaef!=yC2U7tAQ2i>z^IL,yC4!t!kb9j_kH<6=MCHRY6W9Yiw')wlLto+f/W6Y$yY6JQrmW!_1N:Z;/HJ*lQ1o(nc=[[6e8RU0y9Uola(g=[${lT&:+xXi6J.JE<jN1Tb6GF&m32YJi]yCHRY6W9HlVB[I<W=H$y7&G9Qnbrh+e>bT=!P;axeQ>qLKw)R[BGGw^vxb?wBwGYSS,$V%nuWiIEu,e>+{L%R3bj7XxtVE[hoo7F}uhQ|ParE=r@tXLRK9q[gMQJRzmxxBs1Ut7P_o6l61C3oC<Ro&FFYi3`ADDY|X,6=+AYDMK2jg5=TXLRFv)jPnjrzg2b7R;L,(KC{QUU;Ct)QI'07&w^Vo)L01z;&oRz1E3+$Y,t),3W;Hr%;#;,ifz2]DnzIoMR)/nuRn/1e3N[nNxS10m[toEE%2HYY+Bz*xhQQn82Dw8{AM:ODs9YoU~GMf=[Rvu4!/k^;mv/uZbvs0`NDs|OXc}|uc06e077ZwuyBM'4k:mjB58VBwax}i|D&IP:T[EGNw4k5dArk:e7|BS5(E3OVc_q)yEwY)AGDvfyQndMDwGYIqn%.[%B{cols:ivWYR5B{+5LsKG_f7=pNUK8P(+BY_RtH81}S<LsHz+FMKG%Ih>8e|N*/k^;m[G5.){XX;RBv<boU~GcfV<+0FG?:oYuiuJ|<p@0emT+E]xQn@G5.OY.'VE[hFBrIIwoYgM7RRzmxxBrI~ovyBM&zc=R[B58VBwDm*l+zbg!=HTzT$&wboU5GID[hFBrI,(4YvP:IQzmxbjgM,(*52P:I.Jh>*NV3dwF*$Y7RRz{hcM*HmxKC{QxtVE[h[/E(rpuF"

    func testEncode() {
        let base91 = BATBase91J()

        XCTAssertEqual(base91.encode(simpleCase.data(using: .utf8)!), simpleCaseEncoded.data(using: .utf8))
        XCTAssertEqual(base91.encode(complexJSON.data(using: .utf8)!), complexJSONEncoded.data(using: .utf8))
    }

    func testDecode() {
        let base91 = BATBase91J()

        XCTAssertEqual(try! base91.decode(simpleCaseEncoded.data(using: .utf8)!), simpleCase.data(using: .utf8))
        XCTAssertEqual(try! base91.decode(complexJSONEncoded.data(using: .utf8)!), complexJSON.data(using: .utf8))
    }
}
