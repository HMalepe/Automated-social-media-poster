import { useEffect, useState } from 'react';
import { Stack, router } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { supabase } from '@/lib/supabase';
import { Colors } from '@/constants/theme';

export default function RootLayout() {
  const [ready, setReady] = useState(false);

  useEffect(() => {
    supabase.auth.getSession().then(async ({ data: { session } }) => {
      if (!session) {
        router.replace('/auth/login');
      } else {
        // Cache shop_id and shop_name locally for offline use
        const { data } = await supabase
          .from('shops')
          .select('id, name')
          .eq('owner_id', session.user.id)
          .single();
        if (data) {
          await AsyncStorage.setItem('shop_id', data.id);
          await AsyncStorage.setItem('shop_name', data.name);
        }
      }
      setReady(true);
    });

    const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!session) {
        router.replace('/auth/login');
      }
    });

    return () => listener.subscription.unsubscribe();
  }, []);

  if (!ready) return null;

  return (
    <>
      <StatusBar style="light" />
      <Stack screenOptions={{ headerStyle: { backgroundColor: Colors.primary }, headerTintColor: Colors.white, headerTitleStyle: { fontWeight: '700' } }}>
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen name="checkout" options={{ title: 'Checkout', presentation: 'modal' }} />
        <Stack.Screen name="product/new" options={{ title: 'Add Product' }} />
        <Stack.Screen name="product/[barcode]" options={{ title: 'Product' }} />
        <Stack.Screen name="auth/login" options={{ headerShown: false }} />
        <Stack.Screen name="auth/register" options={{ title: 'Create account' }} />
      </Stack>
    </>
  );
}
