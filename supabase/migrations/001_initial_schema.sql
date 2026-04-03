-- AllocCheck — Schema initial
-- 2026-04-03

-- Extension pour chiffrement
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Table des profils utilisateurs
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  display_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des simulations
CREATE TABLE IF NOT EXISTS simulations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  -- Situation personnelle (chiffré conceptuellement — en prod utiliser pgcrypto)
  situation JSONB NOT NULL, -- revenus, foyer, logement, emploi
  -- Résultats
  droits_theoriques JSONB, -- {rsa: 607, apl: 320, prime_activite: 180, ...}
  montant_percu JSONB, -- {rsa: 500, apl: 280, prime_activite: 0, ...}
  ecart JSONB, -- {rsa: 107, apl: 40, prime_activite: 180, ...}
  ecart_total NUMERIC(10,2) DEFAULT 0,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des courriers générés
CREATE TABLE IF NOT EXISTS letters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  simulation_id UUID REFERENCES simulations(id) ON DELETE CASCADE,
  -- Type de courrier
  letter_type TEXT NOT NULL CHECK (letter_type IN ('reclamation_gracieuse', 'saisine_cra')),
  -- Contenu
  content TEXT NOT NULL, -- texte du courrier
  pdf_url TEXT, -- URL du PDF stocké
  -- Aide concernée
  aide_type TEXT NOT NULL, -- rsa, apl, prime_activite, etc.
  montant_reclame NUMERIC(10,2),
  -- Metadata
  is_paid BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des abonnements (suivi côté serveur, RevenueCat est la source de vérité)
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  plan TEXT NOT NULL CHECK (plan IN ('free', 'report', 'letter', 'premium')),
  status TEXT NOT NULL CHECK (status IN ('active', 'expired', 'cancelled')),
  expires_at TIMESTAMPTZ,
  revenuecat_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE simulations ENABLE ROW LEVEL SECURITY;
ALTER TABLE letters ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Policies : chaque utilisateur ne voit que ses données
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view own simulations" ON simulations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own simulations" ON simulations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own simulations" ON simulations FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own simulations" ON simulations FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own letters" ON letters FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own letters" ON letters FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own subscriptions" ON subscriptions FOR SELECT USING (auth.uid() = user_id);

-- Index
CREATE INDEX idx_simulations_user_id ON simulations(user_id);
CREATE INDEX idx_simulations_created_at ON simulations(created_at DESC);
CREATE INDEX idx_letters_user_id ON letters(user_id);
CREATE INDEX idx_letters_simulation_id ON letters(simulation_id);

-- Trigger pour auto-créer le profil après inscription
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
