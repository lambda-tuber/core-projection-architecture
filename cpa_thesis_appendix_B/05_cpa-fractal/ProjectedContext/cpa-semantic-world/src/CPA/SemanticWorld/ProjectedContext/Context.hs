module CPA.SemanticWorld.ProjectedContext.Context where

import CPA.Multiverse.CoreModel.Type

--------------------------------------------------------------------------------
-- Avatar アクション（ProjectedContext）
--
-- 意味論（semantic）における ProjectedContext アクションの定義。
--
-- attacked は純粋関数：与えられた Int ダメージを減らすだけの決定的操作。
--   型：Avatar -> Avatar
--   runProjectedContext から呼ぶとき：return . attacked n で IO に持ち上げる。
--
-- heal は IO 関数：回復値をランダムにする余地があるため IO を持つ。
--   型：Avatar -> IO Avatar
--   runProjectedContext からそのまま渡せる。
--
-- cf. ontological の ProjectedContext（AnotherWorld）：
--   attacked / heal は AnotherWorld モナドの中で World 型クラスのメソッドを通じて操作する。
--   Avatar は World の外に出ない。
--   意味論では Avatar が「外に取り出されて」引数として渡される点が根本的に異なる。
--------------------------------------------------------------------------------

-- | 外界からの作用：ダメージ量を引数で受け取り HP を減らす（純粋関数）
-- HP は 0 未満にならない。
-- 決定的操作なので IO 不要。
attacked :: Int -> Avatar -> Avatar
attacked dmg av = av { _hpAvatar = max 0 (_hpAvatar av - dmg) }

-- | Avatar 内部の能力発動：回復を適用する（IO 関数）
-- 現在は level × 5 固定だが、将来 randomRIO 等でランダム回復値を生成する余地がある。
-- 回復量：level × 5
-- mp消費：固定 10
-- HP は maxHp を超えない、MP は 0 未満にならない。
heal :: Avatar -> IO Avatar
heal av = do
  -- 将来：healAmount <- randomRIO (_levelAvatar av * 3, _levelAvatar av * 7) のように拡張可能
  let healAmount = _levelAvatar av * 5
      mpCost     = 10
      maxHp      = 100   -- 将来的に Avatar フィールドに移す
  return $ av { _hpAvatar = min maxHp (_hpAvatar av + healAmount)
              , _mpAvatar = max 0     (_mpAvatar av - mpCost)
              }
