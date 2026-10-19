import Foundation
import CallKit
func ownCallActionObjects(_ id:UUID)->[CXCallAction] {
  [CXAnswerCallAction(call:id),CXSetMutedCallAction(call:id,muted:true),CXEndCallAction(call:id)]
}
func coarseObservedState(_ call:CXCall)->(UUID,Bool,Bool,Bool) {
  (call.uuid,call.isOutgoing,call.hasConnected,call.hasEnded)
}
