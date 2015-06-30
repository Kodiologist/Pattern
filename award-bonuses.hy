; Pay out earnings from the Newman task as bonuses.

(require kodhy.macros)

(import
  sys
  json
  sqlite3
  boto.mturk.connection)

(setv [db-path json-path] (rest sys.argv))

; The JSON file records how much we paid in bonuses to each
; subject, partly to ensure we don't pay the same bonus multiple
; times. You can exclude a subject from getting a bonus by putting
; an entry for them in the JSON file first.

(try
  (do
    (setv db (sqlite3.connect db-path))
    (setv db.row-factory sqlite3.Row)
    (.execute db "pragma foreign_keys = on;")
    ; We ensure the keys of `winnings` are strings rather than
    ; numbers for better interoperability with JSON.
    (setv winnings (dict (amap (, (str (get it (str "sn"))) (dict it)) (.fetchall (db.execute "
        select sn, workerid, assignmentid, cents
        from
            MTurk join
            (select sn, sum(v) as cents
                from D
                where k like 'newman.task.won.b%.t%'
                    and sn in (select sn from MTurk where reconciled)
                group by sn)
            using (sn)"))))))
  (finally
    (.close db)))

(setv j (with [[o (open json-path)]]
  (json.load o)))

(setv mt (kwc boto.mturk.connection.MTurkConnection :host
  (if (.get j "production")
    "mechanicalturk.amazonaws.com"
    "mechanicalturk.sandbox.amazonaws.com")))

(for [sn winnings]
  (unless (in sn (get j "s"))
    (setv cents (get winnings sn "cents"))
    (.grant-bonus mt
      (get winnings sn "workerid")
      (get winnings sn "assignmentid")
      (.get-price-as-price mt (/ cents 100))
      "These are your in-task earnings from the HIT \"Decision-Making\".")
    (print (.format "Bonused {} ({}) - {} cents" sn (get winnings sn "workerid") cents))
    (setv (get j "s" sn) cents)
    ; Re-write the JSON file immediately in case this program
    ; crashes mid-loop.
    (with [[o (open json-path "w")]]
      (json.dump j o))))
