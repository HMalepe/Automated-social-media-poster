import React, { useState } from 'react';
import { View, Text, TextInput, StyleSheet, Alert, KeyboardAvoidingView, Platform, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/Button';
import { Colors, FontSize, Spacing, BorderRadius } from '@/constants/theme';

export default function RegisterScreen() {
  const [shopName, setShopName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const handleRegister = async () => {
    if (!shopName || !email || !password) {
      Alert.alert('Missing fields', 'Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      Alert.alert('Weak password', 'Password must be at least 6 characters.');
      return;
    }
    setLoading(true);
    const { data, error } = await supabase.auth.signUp({ email, password });
    if (error || !data.user) {
      setLoading(false);
      Alert.alert('Registration failed', error?.message ?? 'Something went wrong.');
      return;
    }

    const { error: shopError } = await supabase
      .from('shops')
      .insert({ owner_id: data.user.id, name: shopName });

    setLoading(false);
    if (shopError) {
      Alert.alert('Shop setup failed', shopError.message);
      return;
    }

    Alert.alert('Account created!', 'Welcome to Spaza POS.', [
      { text: 'Get started', onPress: () => router.replace('/') },
    ]);
  };

  return (
    <KeyboardAvoidingView style={styles.flex} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
        <Text style={styles.title}>Create your shop</Text>
        <Text style={styles.subtitle}>Set up your Spaza POS account in seconds</Text>

        <Text style={styles.label}>Shop name</Text>
        <TextInput
          style={styles.input}
          value={shopName}
          onChangeText={setShopName}
          placeholder="e.g. Mama Thandi's Spaza"
          autoCapitalize="words"
        />

        <Text style={styles.label}>Email</Text>
        <TextInput
          style={styles.input}
          value={email}
          onChangeText={setEmail}
          placeholder="you@email.com"
          keyboardType="email-address"
          autoCapitalize="none"
        />

        <Text style={styles.label}>Password</Text>
        <TextInput
          style={styles.input}
          value={password}
          onChangeText={setPassword}
          placeholder="At least 6 characters"
          secureTextEntry
        />

        <Button label="Create account" onPress={handleRegister} loading={loading} size="lg" style={styles.btn} />
        <Button label="Back to login" onPress={() => router.back()} variant="ghost" style={styles.btn} />
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: Colors.background },
  container: { flexGrow: 1, padding: Spacing.xl, paddingTop: Spacing.xxl },
  title: { fontSize: FontSize.xxl, fontWeight: '800', color: Colors.gray800, marginBottom: Spacing.xs },
  subtitle: { fontSize: FontSize.md, color: Colors.gray400, marginBottom: Spacing.xl },
  label: { fontSize: FontSize.sm, fontWeight: '600', color: Colors.gray600, marginBottom: Spacing.xs },
  input: {
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: BorderRadius.md,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm + 2,
    fontSize: FontSize.md,
    color: Colors.gray800,
    marginBottom: Spacing.md,
  },
  btn: { marginTop: Spacing.sm },
});
