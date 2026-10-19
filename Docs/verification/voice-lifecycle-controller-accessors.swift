
extension VoiceInputController { var gateToken:Int { generation };var gateHasCapture:Bool { capture != nil };var gateSynthetic:Bool { synthetic };func gateReceive(_ text:String,final:Bool=false,problem:String?=nil,ticket:Int) { receive(text:text,final:final,problem:problem,ticket:ticket) } }
