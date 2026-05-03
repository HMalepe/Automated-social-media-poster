import React, { useState, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { CameraView, useCameraPermissions, BarcodeScanningResult } from 'expo-camera';
import { Colors, FontSize, Spacing } from '@/constants/theme';

interface BarcodeScannerProps {
  onScan: (barcode: string) => void;
  active?: boolean;
}

export function BarcodeScanner({ onScan, active = true }: BarcodeScannerProps) {
  const [permission, requestPermission] = useCameraPermissions();
  const lastScanned = useRef<string | null>(null);
  const cooldownRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  if (!permission) {
    return <View style={styles.container} />;
  }

  if (!permission.granted) {
    return (
      <View style={styles.permissionContainer}>
        <Text style={styles.permissionText}>Camera access needed to scan barcodes</Text>
        <TouchableOpacity style={styles.permissionBtn} onPress={requestPermission}>
          <Text style={styles.permissionBtnText}>Allow Camera</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const handleBarcode = (result: BarcodeScanningResult) => {
    if (!active) return;
    const { data } = result;
    if (data === lastScanned.current) return;

    lastScanned.current = data;
    onScan(data);

    // 2-second cooldown to prevent duplicate scans
    if (cooldownRef.current) clearTimeout(cooldownRef.current);
    cooldownRef.current = setTimeout(() => {
      lastScanned.current = null;
    }, 2000);
  };

  return (
    <View style={styles.container}>
      <CameraView
        style={styles.camera}
        facing="back"
        barcodeScannerSettings={{ barcodeTypes: ['ean13', 'ean8', 'upc_a', 'upc_e', 'code128', 'code39', 'qr'] }}
        onBarcodeScanned={handleBarcode}
      />
      <View style={styles.overlay}>
        <View style={styles.scanWindow} />
        <Text style={styles.hint}>Point at a product barcode</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000' },
  camera: { flex: 1 },
  permissionContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: Spacing.xl,
    backgroundColor: Colors.background,
  },
  permissionText: {
    fontSize: FontSize.md,
    color: Colors.gray600,
    textAlign: 'center',
    marginBottom: Spacing.lg,
  },
  permissionBtn: {
    backgroundColor: Colors.primary,
    paddingVertical: Spacing.sm,
    paddingHorizontal: Spacing.xl,
    borderRadius: 8,
  },
  permissionBtnText: { color: Colors.white, fontWeight: '600', fontSize: FontSize.md },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    alignItems: 'center',
    justifyContent: 'center',
  },
  scanWindow: {
    width: 260,
    height: 160,
    borderRadius: 12,
    borderWidth: 3,
    borderColor: Colors.accent,
    backgroundColor: 'transparent',
  },
  hint: {
    color: Colors.white,
    fontSize: FontSize.sm,
    marginTop: Spacing.md,
    backgroundColor: 'rgba(0,0,0,0.5)',
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
    borderRadius: 20,
    overflow: 'hidden',
  },
});
