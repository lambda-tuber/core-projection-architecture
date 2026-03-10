module CPA.OntologicalWorld.ProjectedContext.Context where

import CPA.OntologicalWorld.CoreModel.Type

--------------------------------------------------------------------------------
-- Avatar アクション（World m 制約・内在化）
--
-- attacked：物理的な作用。世界によらず共通ロジック。
--   takeAvatar → ダメージ計算（純粋）→ putAvatar
-- heal：世界の性質に依存する能力発動。healInWorld に完全委譲（1行）
--   世界が takeAvatar → 回復計算 → putAvatar を完結させる責務を持つ
--
-- 意味論との対比：
--   意味論：heal が Avatar を引数で受け取る純粋関数
--   存在論：heal = healInWorld（世界に完全委譲）
--------------------------------------------------------------------------------

-- | 外界からの作用：ダメージ量を引数で受け取り HP を減らす
-- 物理的な作用のため世界共通ロジック。HP は 0 未満にならない。
attacked :: World m => Int -> m (Avatar m)
attacked dmg = do
  av <- takeAvatar
  let av' = av { _hpAvatarO = max 0 (_hpAvatarO av - dmg) }
  putAvatar av'
  return av'

-- | Avatar 内部の能力発動：healInWorld に完全委譲
heal :: World m => m (Avatar m)
heal = healInWorld
