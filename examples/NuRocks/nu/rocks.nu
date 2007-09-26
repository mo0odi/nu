;; rocks.nu
;;  Nu Rocks.  A Nu take on asteroids.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(load "nu")

(global NUMBER_OF_ROCKS 10)
(global MISSILE_SPEED   10)
(global MISSILE_LIFE    250)
(global TURN_ANGLE      0.2)
(global ACCELERATION    1)
(global SPEED_LIMIT     10)

(global KEY_SPACE       49)
(global KEY_LEFT_ARROW  123)
(global KEY_RIGHT_ARROW 124)
(global KEY_DOWN_ARROW  125)
(global KEY_UP_ARROW    126)
(global KEY_P           35)
(global KEY_N           45)
(global KEY_R           15)

(class NSMutableArray
     (- removeObjectsIf:block is
        (self removeObjectsInArray:(self select:block))))

(class NSBezierPath
     (- transform:transform is
        (self transformUsingAffineTransform:transform)
        self))

(class NSAffineTransform
     (- transformRect:rect is
        (set origin   (self transformPoint:(list (rect first) (rect second))))
        (set opposite (self transformPoint:(list (+ (rect first) (rect third)) (+ (rect second) (rect fourth)))))
        (list (origin first) (origin second) (- (opposite first) (origin first)) (- (opposite second) (origin second)))))

(class NuRocksView is NSView
     (ivars)
     
     (- init is
        (self initWithFrame:'(0 0 100 100))
        (set @gameRect '(0 0 600 600))
        (set @game ((NuRocksGame alloc) initWithRect:@gameRect))
        (set @timer (NSTimer scheduledTimerWithTimeInterval:(/ 1.0 60) target:self selector:"tick:" userInfo:nil repeats:YES))
        (self setAutoresizingMask:(+ NSViewWidthSizable NSViewHeightSizable))
        self)
     
     (- dealloc is
        (@timer invalidate)
        (super dealloc))
     
     (- drawRect:rect is
        (((NSColor whiteColor) colorWithAlphaComponent:0.3) set)
        (NSRectFill rect)
        (set $transform (self computeTransform:rect))
        ($transform transformRect:@gameRect)
        (set border ($transform transformRect:@gameRect))
        (NSBezierPath clipRect:border)
        (if (eq (self inLiveResize) YES) (@game resize))
        (@game draw)
        ((NSColor grayColor) set)
        (set edge (NSBezierPath bezierPathWithRect:border))
        (edge setLineWidth:30.0)
        (edge stroke))
     
     (- acceptsFirstResponder is YES)
     
     (- keyDown:event is
        (@game keyDown:(event keyCode)))
     
     (- keyUp:event is
        (@game keyUp:(event keyCode)))
     
     (- tick:timer is
        (@game tick:timer)
        (self setNeedsDisplay:YES))
     
     (- computeTransform:frame is
        (set xscale (* 0.95 (/ (frame third) (@gameRect third))))
        (set yscale (* 0.95 (/ (frame fourth) (@gameRect fourth))))
        (set scale (cond ((< xscale yscale) xscale) (t yscale)))
        (set $scale scale)
        (set dx (* 0.5 (- (frame third) (* scale (@gameRect third)))))
        (set dy (* 0.5 (- (frame fourth) (* scale (@gameRect fourth)))))
        (set transform (NSAffineTransform transform))
        (transform translateXBy:(+ dx (frame first)) yBy:(+ dy (frame second)))
        (transform scaleXBy:scale yBy:scale)
        (transform translateXBy:(@gameRect first) yBy:(@gameRect second))
        transform)
     
     (- windowWillClose:notification is
        (@timer invalidate)
        (set @timer nil)))

(class NuRocksGame is NSObject
     (ivars)
     
     (- initWithRect:bounds is
        (self init)
        (set $wrap nil)
        (set @bounds bounds)
        (set @paused YES)
        (set @score 10)
        (self addShip)
        (set @rocks ((NSMutableArray alloc) init))
        (set @rocksToAdd NUMBER_OF_ROCKS)
        (self addRocks)
        (set @missiles ((NSMutableArray alloc) init))
        (set @sounds (NSMutableDictionary dictionaryWithList:(list "shipDestroyed" (NSSound soundNamed:"Submarine")
                                                                   "rockDestroyed" (NSSound soundNamed:"Bottle")
                                                                   "shoot" (NSSound soundNamed:"Pop"))))
        self)
     
     (- addShip is
        (set newx (* 0.5 (@bounds third)))
        (set newy (* 0.5 (@bounds fourth)))
        (set @ship ((Ship alloc) initWithPosition:(list newx newy))))
     
     (- addShipRandomly is
        (set unfinished t)
        (while unfinished
               (set newx (+ (* 0.1 (@bounds third)) (rand (* 0.8 (@bounds third)))))
               (set newy (+ (* 0.1 (@bounds fourth)) (rand (* 0.8 (@bounds fourth)))))
               (set @ship ((Ship alloc) initWithPosition:(list newx newy)))
               (@rocks each:
                       (do (rock)
                           (if (@ship collidesWith:rock)
                               (@ship setTtl:0))))
               (if (!= (@ship ttl) 0) (set unfinished nil))))
     
     (- addRocks is
        (@rocksToAdd times:
             (do (i) (@rocks addObject:((Rock alloc) initWithPosition:(list (rand (@bounds third)) (rand (@bounds fourth)))))))
        (set @maximum 20)
        (set @rocksToAdd (+ 2 (@rocksToAdd)))
        (@rocks removeObjectsIf:(do (rock) (rock collidesWith:@ship))))
     
     (- resize is
        (set @topattributes nil)
        (set @bottomattributes nil))
     
     (- drawTextAtTop:text is
        (set topCenter ($transform transformPoint:(list (* 0.50 (@bounds third))
                                                        (* 0.75 (@bounds fourth)))))
        (unless @topattributes
                (set @topattributes (NSMutableDictionary dictionaryWithList:
                                         (list NSForegroundColorAttributeName ((NSColor whiteColor) colorWithAlphaComponent:1.0)
                                               NSFontAttributeName (NSFont boldSystemFontOfSize:(* 48.0 $scale))))))
        (set size (text sizeWithAttributes:@topattributes))
        (text drawAtPoint:(list (- (topCenter first) (* (size first) 0.5))
                                (- (topCenter second) (* (size second) 0.5)))
              withAttributes:@topattributes))
     
     (- drawTextAtBottom:text is
        (set bottomCenter ($transform transformPoint:(list (* 0.50 (@bounds third))
                                                           (* 0.25 (@bounds fourth)))))
        (unless @bottomattributes
                (set @bottomattributes (NSMutableDictionary dictionaryWithList:
                                            (list NSForegroundColorAttributeName ((NSColor whiteColor) colorWithAlphaComponent:1.0)
                                                  NSFontAttributeName (NSFont boldSystemFontOfSize:(* 24.0 $scale))))))
        (set size (text sizeWithAttributes:@bottomattributes))
        (text drawAtPoint:(list (- (first bottomCenter) (* (first size) 0.5))
                                (- (second bottomCenter) (* (second size) 0.5)))
              withAttributes:@bottomattributes))
     
     (- drawScore is
        (set text ((@score intValue) stringValue))
        (set position ($transform transformPoint:(list (* 0.50 (@bounds third))
                                                       (* 0.05 (@bounds fourth)))))
        (unless @scoreattributes
                (set @scoreattributes (NSMutableDictionary dictionaryWithList:
                                           (list NSForegroundColorAttributeName ((NSColor redColor) colorWithAlphaComponent:1.0)
                                                 NSFontAttributeName (NSFont boldSystemFontOfSize:(* 16.0 $scale))))))
        (set size (text sizeWithAttributes:@scoreattributes))
        (text drawAtPoint:(list (- (first position) (* (first size) 0.5))
                                (- (second position) (* (second size) 0.5)))
              withAttributes:@scoreattributes))
     
     
     (- draw is
        (((NSColor blackColor) colorWithAlphaComponent:0.95) set)
        (NSRectFill ($transform transformRect:@bounds))
        (@rocks each:(do (rock) (rock draw)))
        (if @ship (@ship draw))
        (@missiles each:(do (missile) (missile draw)))
        (cond ((eq @paused 1)
               (self drawTextAtTop:"Nu Rocks")
               (self drawTextAtBottom:"press p to play"))
              ((eq @ship nil)
               (self drawTextAtBottom:"press n for another chance"))
              ((eq (@rocks count) 0)
               (self drawTextAtBottom:"press r for more rocks"))
              (t
                (self drawScore))))
     
     (- tick:timer is
        (if (eq @paused 0)
            (set @score (+ @score 0.05))
            (@rocks each:(do (rock) (rock moveWithBounds:@bounds)))
            (if @ship (@ship moveWithBounds:@bounds))
            (@missiles each:(do (missile) (missile moveWithBounds:@bounds)))
            (@rocks each:
                    (do (rock)
                        (@missiles each:
                             (do (missile)
                                 (if (missile collidesWith:rock)
                                     (missile setTtl:0)
                                     (cond ((> (rock radius) @maximum)
                                            (rock setTtl:0)
                                            (set @score (+ @score 100))
                                            (set @maximum (+ @maximum 30)))
                                           (t (rock setRadius:(+ (rock radius) 10))))
                                     ((@sounds objectForKey:"rockDestroyed") play))))
                        (if (and @ship (@ship collidesWith:rock))
                            (@ship setTtl:0)
                            (set @score (- @score 200))
                            (if (< @score 0) (set @score 0))
                            ((@sounds objectForKey:"shipDestroyed") play))))
            (if (and @ship (eq (@ship ttl) 0)) (set @ship nil))
            (@rocks removeObjectsIf:(do (rock) (eq (rock ttl) 0)))
            (@missiles removeObjectsIf:(do (missile) (eq (missile ttl) 0)))))
     
     (- keyDown:code is
        (case code
              (KEY_SPACE         (if (and @ship (> @score 0))
                                     (@missiles addObject:(@ship shoot))
                                     (set @score (- @score 1))
                                     ((@sounds objectForKey:"shoot") play)))
              (KEY_LEFT_ARROW    (if @ship (@ship setAngle:TURN_ANGLE)))
              (KEY_RIGHT_ARROW   (if @ship (@ship setAngle:(- 0 TURN_ANGLE))))
              (KEY_UP_ARROW      (if @ship (@ship setAcceleration:ACCELERATION)))
              (KEY_DOWN_ARROW    (if @ship (@ship setAcceleration:(- 0 ACCELERATION))))
              (KEY_P             (set @paused (- 1 @paused)))
              (KEY_N             (unless @ship (self addShipRandomly)))
              (KEY_R             (if (eq (@rocks count) 0) (self addRocks)))
              (t                 (puts "key pressed: #{code}"))))
     
     (- keyUp:code is
        (case code
              (KEY_LEFT_ARROW    (if @ship (@ship setAngle:0)))
              (KEY_RIGHT_ARROW   (if @ship (@ship setAngle:0)))
              (KEY_UP_ARROW      (if @ship (@ship setAcceleration:0)))
              (KEY_DOWN_ARROW    (if @ship (@ship setAcceleration:0)))
              (t nil))))

(class Sprite is NSObject
     (ivars)
     
     (- position is @position)
     (- velocity is @velocity)
     (- radius is @radius)
     (- setRadius:r is (set @radius r))
     (- ttl is @ttl)
     (- setTtl:ttl is (set @ttl ttl))
     
     (- initWithPosition:position is
        (self init)
        (set @position position)
        (set @velocity '(0 0))
        (set @ttl -1)
        self)
     
     (- moveWithBounds:bounds is
        (if (> @ttl 0) (set @ttl (- @ttl 1)))
        (set px (+ (first @position) (first @velocity)))
        (set py (+ (second @position) (second @velocity)))
        
        (cond (($wrap)
               (cond ((< px 0) (set px (third bounds)))
                     ((> px (third bounds)) (set px 0))
                     (t nil))
               (cond ((< py 0) (set py (fourth bounds)))
                     ((> py (fourth bounds)) (set py 0))
                     (t nil)))
              (t ;; bouncing
                 (set vx (@velocity first))
                 (set vy (@velocity second))
                 (cond ((< px @radius) (set vx (* vx -1)))
                       ((> px (- (third bounds) @radius)) (set vx (* vx -1)))
                       (t nil))
                 (cond ((< py @radius) (set vy (* vy -1)))
                       ((> py (- (fourth bounds) @radius)) (set vy (* vy -1)))
                       (t nil))
                 (set @velocity (list vx vy))))
        (set @position (list px py)))
     
     (- collidesWith:sprite is
        (set spriteposition (sprite position))
        (set dx (- (first @position) (first spriteposition)))
        (set dy (- (second @position) (second spriteposition)))
        (set r (+ @radius (sprite radius)))
        (cond ((> dx r) nil)
              ((> (- 0 dx) r) nil)
              ((> dy r) nil)
              ((> (- 0 dy) r) nil)
              ((> (+ (* dx dx) (* dy dy)) (* r r)) nil)
              (t YES))))

(class Rock is Sprite
     (- initWithPosition:position is
        (super initWithPosition:position)
        (set @velocity (list (/ (- (rand 10) 5) 10) (/ (- (rand 10) 5) 10)))
        (set @color ((case (rand 4)
                           (0 (NSColor yellowColor))
                           (1 (NSColor greenColor))
                           (2 (NSColor blueColor))
                           (3 (NSColor orangeColor))) colorWithAlphaComponent:0.8))
        (set @radius 20)
        self)
     (- draw is
        (@color set)
        (set path (NSBezierPath bezierPathWithOvalInRect:(list (- (first @position) @radius)
                                                               (- (second @position) @radius)
                                                               (* 2 @radius)
                                                               (* 2 @radius))))
        (path moveToPoint:(list (first @position) (+ (second @position) @radius)))
        (path lineToPoint:(list (first @position) (- (second @position) @radius)))
        (path moveToPoint:(list (- (first @position) (* @radius 0.707)) (- (second @position) (* @radius 0.707))))
        (path lineToPoint:@position)
        (path lineToPoint:(list (+ (first @position) (* @radius 0.707)) (- (second @position) (* @radius 0.707))))
        (path setLineWidth:(* @radius 0.2))
        ((path transform:$transform) stroke)))

(class Ship is Sprite
     (- setAngle:a is (set @angle a))
     
     (- setAcceleration:a is (set @acceleration a))
     
     (- initWithPosition:position is
        (super initWithPosition:position)
        (set @radius 10)
        (set @color (NSColor redColor))
        (set @direction '(0 1))
        (set @angle 0)
        (set @acceleration 0)
        self)
     
     (- moveWithBounds:bounds is
        (super moveWithBounds:bounds)
        (cond ((!= @angle 0)
               (set cosA (NuMath cos:@angle))
               (set sinA (NuMath sin:@angle))
               (set x (- (* cosA (first @direction)) (* sinA (second @direction))))
               (set y (+ (* cosA (second @direction)) (* sinA (first @direction))))
               (set @direction (list x y)))
              (t nil))
        (cond ((!= @acceleration 0)
               (set speed (NuMath sqrt:(+ (NuMath square:(+ (first @velocity) (* @acceleration (first @direction))))
                                          (NuMath square:(+ (second @velocity) (* @acceleration (second @direction)))))))
               (cond ((< speed SPEED_LIMIT)
                      (set @velocity (list (+ (first @velocity) (* @acceleration (first @direction)))
                                           (+ (second @velocity) (* @acceleration (second @direction))))))
                     (t nil)))
              (t nil)))
     
     (- draw is
        (@color set)
        (set x0 (first @position))
        (set y0 (second @position))
        (set x (first @direction))
        (set y (second @direction))
        (set r @radius)
        (set path (NSBezierPath bezierPath))
        (path moveToPoint:(list (+ x0 (* r x))
                                (+ y0 (* r y))))
        (path lineToPoint:(list (+ x0 (* r (- y x)))
                                (+ y0 (* r (- 0 x y)))))
        (path lineToPoint:(list x0 y0))
        (path lineToPoint:(list (+ x0 (* r (- 0 x y)))
                                (+ y0 (* r (- x y)))))
        ((path transform:$transform) fill))
     
     (- shoot is
        (set missilePosition (list (+ (first @position) (first @direction))
                                   (+ (second @position) (second @direction))))
        (set missileVelocity (list (+ (* MISSILE_SPEED (first @direction)) (first @velocity))
                                   (+ (* MISSILE_SPEED (second @direction)) (second @velocity))))
        ((Missile alloc) initWithPosition:missilePosition velocity:missileVelocity color:@color)))

(class Missile is Sprite
     (- initWithPosition:position velocity:velocity color:color is
        (self initWithPosition:position)
        (set @velocity velocity)
        (set @color color)
        (set @radius 3)
        (set @ttl MISSILE_LIFE)
        self)
     
     (- draw is
        (@color set)
        (((NSBezierPath bezierPathWithOvalInRect:
               (list
                    (- (first @position) @radius)
                    (- (second @position) @radius)
                    (* 2 @radius)
                    (* 2 @radius)))
          transform:$transform) fill)))

(class NuRocksWindowController is NSObject
     (ivars)
     
     (- initWithView:view is
        (self init)
        (set @window ((NSWindow alloc)
                      initWithContentRect:'(30 200 800 800)
                      styleMask:(+ NSTitledWindowMask NSClosableWindowMask NSMiniaturizableWindowMask NSResizableWindowMask)
                      backing:NSBackingStoreBuffered
                      defer:NO))
        (set @view view)
        (@view set:(autoresizingMask:(+ NSViewWidthSizable NSViewHeightSizable)))
        (@window set:(contentView:@view opaque:NO title:"Nu Rocks" delegate:self releasedWhenClosed:NO))
        (@window center)
        (@window makeKeyAndOrderFront:self)
        self)
     
     ;; delegate method that informs us when the window is about to close
     (- windowWillClose:notification is
        (@view windowWillClose:notification)))

(function rocks ()
     ((NuRocksWindowController alloc) initWithView:((NuRocksView alloc) init)))
