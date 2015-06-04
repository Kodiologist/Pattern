; This script estimates the total amount of time subjects will
; have to spend waiting.

(require kodhy.macros)

(import
  [math [log]]
  [scipy.stats :as scist]
  [kodhy.util [rd]])

(setv blocks 20)
(setv trials_per_block 3)
(setv fixed_dwait 5.)
(setv median_rand_dwait 5.)

(setv n-waits (* blocks trials_per_block))
(setv mean_rand_dwait (/ median_rand_dwait (log 2)))

;(import [numpy :as np])
;(setv sample-size 10000)
;(setv samples (amap
;  (let [[v (np.random.rand n-waits)]]
;    (np.sum (+ fixed_dwait (* mean_rand_dwait (- (np.log v))))))
;  (range sample-size)))
;(print (rd 1 (/ (kwc np.percentile samples :q [2.5 50 97.5]) 60)))

(setv quants (kwc scist.erlang.ppf [.025 .5 .975]
  :loc (* fixed_dwait n-waits)
  :a n-waits
  :scale mean_rand_dwait))
(print (rd 1 (/ quants 60)) "minutes")
