/*
 * "Hello Swift, Goodbye Obj-C."
 * Converted by 'objc2swift'
 *
 * https://github.com/yahoojapan/objc2swift
 */

class DBChunkInputStream: NSInputStream, NSStreamDelegate
{
    private private(set) var parentStream: NSInputStream
    private var parentStreamStatus: NSStreamStatus
    private private(set) var streamDelegate : NSStreamDelegate?
    private var copiedCallback: CFReadStreamClientCallBack
    private var copiedContext: CFStreamClientContext
    private var requestedEvents: CFOptionFlags
    private private(set) var startBytes: UInt
    private private(set) var endBytes: UInt
    private private(set) var totalBytesToRead: UInt
    private var totalBytesRead: UInt
    
    init(fileUrl: NSURL, startBytes: UInt, endBytes: UInt)
    {
        _parentStream = NSInputStream(uRL: fileUrl)
        _parentStream.setDelegate(self)
        NSAssert(endBytes > startBytes, "End location (%lu) needs to be greater than start location (%lu)", endBytes as! UInt64, startBytes as! UInt64)
        _startBytes = startBytes
        _endBytes = endBytes
        _totalBytesToRead = endBytes - startBytes
        _totalBytesRead = 0
    }
    
    func open()
    {
        _parentStream.open()
        _parentStream.setProperty((_startBytes), forKey: NSStreamFileCurrentOffsetKey)
        _parentStreamStatus = NSStreamStatusOpen
    }
    
    func close()
    {
        _parentStream.close()
        _parentStreamStatus = NSStreamStatusClosed
    }
    
    var delegate : NSStreamDelegate? = self
    {
        set
        {
            if newValue == nil
            {
                _streamDelegate = self
            }
            else
            {
                _streamDelegate = newValue
            }
        }
        get
        {
            return _streamDelegate
        }
    }
    
    func scheduleInRunLoop(aRunLoop: NSRunLoop, forMode mode: String)
    {
        _parentStream.scheduleInRunLoop(aRunLoop, forMode: mode)
    }
    
    func removeFromRunLoop(aRunLoop: NSRunLoop, forMode mode: String)
    {
        _parentStream.removeFromRunLoop(aRunLoop, forMode: mode)
    }
    
    func propertyForKey(key: String) -> AnyObject
    {
        return _parentStream.propertyForKey(key)
    }
    
    func setProperty(property: AnyObject, forKey key: String) -> Bool
    {
        return _parentStream.setProperty(property, forKey: key)
    }
    
    func streamStatus() -> NSStreamStatus
    {
        return _parentStreamStatus
    }
    
    func streamError() -> NSError
    {
        return _parentStream.streamError()
    }
    
    func read(buffer: uint8_t, maxLength len: UInt) -> Int
    {
        var bytesToRead = len
        var bytesRemaining = _totalBytesToRead - _totalBytesRead
        if len > bytesRemaining {
            bytesToRead = bytesRemaining
        }
        var bytesRead = _parentStream.read(buffer, maxLength: bytesToRead)
        _totalBytesRead += bytesRead
        return bytesRead
    }
    
    func getBuffer(buffer: uint8_t, length len: UInt) -> Bool
    {
        return false
    }
    
    func hasBytesAvailable() -> Bool
    {
        var bytesRemaining = _totalBytesToRead - _totalBytesRead
        if bytesRemaining == 0 {
            _parentStreamStatus = NSStreamStatusAtEnd
            return false
        }
        return _parentStream.hasBytesAvailable()
    }
    
    func _scheduleInCFRunLoop(aRunLoop: CFRunLoopRef, forMode aMode: CFStringRef)
    {
        CFReadStreamScheduleWithRunLoop(_parentStream as! CFReadStreamRef, aRunLoop, aMode)
    }
    
    func _setCFClientFlags(inFlags: CFOptionFlags, callback inCallback: CFReadStreamClientCallBack, context inContext: CFStreamClientContext) -> Bool
    {
        if inCallback {
            _requestedEvents = inFlags
            _copiedCallback = inCallback
            memcpy(&_copiedContext, inContext, sizeof(CFStreamClientContext))
            // [error 179:46] mismatched input 'retain' expecting IDENTIFIER
        } else {
            _requestedEvents = kCFStreamEventNone
            _copiedCallback = nil
            if _copiedContext.info && _copiedContext.release {
                _copiedContext.release(_copiedContext.info)
            }
            memset(&_copiedContext, 0, sizeof(CFStreamClientContext))
        }
        return true
    }
    
    func _unscheduleFromCFRunLoop(aRunLoop: CFRunLoopRef, forMode aMode: CFStringRef)
    {
        CFReadStreamUnscheduleFromRunLoop(_parentStream as! CFReadStreamRef, aRunLoop, aMode)
    }
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent)
    {
        assert(aStream == _parentStream)
        switch eventCode {
        case .openCompleted:
            if _requestedEvents & kCFStreamEventOpenCompleted {
                _copiedCallback(self as! CFReadStreamRef, kCFStreamEventOpenCompleted, _copiedContext.info)
            }
                   
        case .hasBytesAvailable:
            if _requestedEvents & kCFStreamEventHasBytesAvailable {
                _copiedCallback(self as! CFReadStreamRef, kCFStreamEventHasBytesAvailable, _copiedContext.info)
            }
                   
        case .errorOccurred:
            if _requestedEvents & kCFStreamEventErrorOccurred {
                _copiedCallback(self as! CFReadStreamRef, kCFStreamEventErrorOccurred, _copiedContext.info)
            }
                   
        case .endEncountered:
            if _requestedEvents & kCFStreamEventEndEncountered {
                _copiedCallback(self as! CFReadStreamRef, kCFStreamEventEndEncountered, _copiedContext.info)
            }
                   
        case .hasSpaceAvailable: ()
        default: ()
                 
        }
    }
}
