-- ============================================
-- Soundora Maqam Catalog
-- Run AFTER setup.sql and seed_songs.sql
-- ============================================

-- 1. Maqam mapping table (song_id -> maqam)
CREATE TABLE IF NOT EXISTS public.song_maqams (
  song_id BIGINT PRIMARY KEY REFERENCES public."Songs"(id) ON DELETE CASCADE,
  maqam TEXT NOT NULL,
  confidence NUMERIC DEFAULT 0.5,
  detected_at TIMESTAMPTZ DEFAULT now()
);

-- 2. RLS
ALTER TABLE public.song_maqams ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maqams: public read"
  ON public.song_maqams FOR SELECT
  USING (true);

CREATE POLICY "Maqams: authenticated insert"
  ON public.song_maqams FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Maqams: authenticated update"
  ON public.song_maqams FOR UPDATE
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Maqams: service_role bypass"
  ON public.song_maqams FOR ALL
  USING (auth.role() = 'service_role');

-- 3. Seed: curated maqam assignment for the 12 sample songs.
-- Canonical keys: Rast, Nahawand, Ajam, Hijaz, Saba, Kurd, Sikah, Bayati.
INSERT INTO public.song_maqams (song_id, maqam, confidence) VALUES
(1,  'Nahawand', 0.62), -- Blinding Lights
(2,  'Ajam',     0.58), -- Shape of You
(3,  'Hijaz',    0.55), -- Bohemian Rhapsody
(4,  'Bayati',   0.60), -- Someone Like You
(5,  'Kurd',     0.57), -- Dance Monkey
(6,  'Saba',     0.54), -- Bad Guy
(7,  'Ajam',     0.59), -- Levitating
(8,  'Rast',     0.53), -- Watermelon Sugar
(9,  'Ajam',     0.56), -- Peaches
(10, 'Nahawand', 0.61), -- Stay
(11, 'Bayati',   0.58), -- Save Your Tears
(12, 'Hijaz',    0.52)  -- Montero
ON CONFLICT (song_id) DO UPDATE SET maqam = EXCLUDED.maqam;
