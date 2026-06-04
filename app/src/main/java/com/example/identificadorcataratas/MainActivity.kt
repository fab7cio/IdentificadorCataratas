package com.example.identificadorcataratas

import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage // Asegúrate de importar Coil para renderizar imágenes por URI
import com.example.identificadorcataratas.ui.theme.IdentificadorCataratasTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.random.Random
import androidx.compose.runtime.mutableIntStateOf

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            IdentificadorCataratasTheme {
                Scaffold(
                    modifier = Modifier.fillMaxSize(),
                    containerColor = Color(0xFFF8F9FA)
                ) { innerPadding ->
                    PrototipoSprintCataratas(modifier = Modifier.padding(innerPadding))
                }
            }
        }
    }
}

@Composable
fun PrototipoSprintCataratas(modifier: Modifier = Modifier) {
    var imageUri by remember { mutableStateOf<Uri?>(null) }
    var estaProcesando by remember { mutableStateOf(false) }
    var resultadoTipo by remember { mutableStateOf<String?>(null) }
    var confianza by remember { mutableIntStateOf(0) }
    var tiempoInferencia by remember { mutableIntStateOf(0) }

    val coroutineScope = rememberCoroutineScope()
    val clasesCatarata = listOf("Cortical (C)", "Nuclear (N)", "Subcapsular (P)", "Normal (Sin anomalías)")

    // Lanzador nativo para abrir la galería del smartphone (HU-03)
    val galleryLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        if (uri != null) {
            imageUri = uri
            resultadoTipo = null // Resetea diagnósticos previos al subir nueva foto
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        // --- 1. ENCABEZADO CLÍNICO ---
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = "SISTEMA DE CLASIFICACIÓN MÓVIL",
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = Color(0xFF6B7280),
                letterSpacing = 1.5.sp
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Diagnóstico Local",
                fontSize = 26.sp,
                fontWeight = FontWeight.ExtraBold,
                color = Color(0xFF1F2937)
            )
        }

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .height(300.dp),
            shape = RoundedCornerShape(20.dp),
            border = BorderStroke(1.dp, Color(0xFFE5E7EB)),
            colors = CardDefaults.cardColors(containerColor = Color(0xFFF3F4F6))
        ) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                if (imageUri != null) {
                    // Muestra la imagen real seleccionada por la lámpara de hendidura
                    AsyncImage(
                        model = imageUri,
                        contentDescription = "Imagen médica ingresada",
                        modifier = Modifier.fillMaxSize().clip(RoundedCornerShape(20.dp)),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    // Estado vacío inicial
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "No se ha cargado ninguna muestra",
                            color = Color(0xFF9CA3AF),
                            fontSize = 14.sp
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Button(
                            onClick = { galleryLauncher.launch("image/*") },
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4B5563)),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Icon(Icons.Default.Add, contentDescription = null)
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Abrir Galería")
                        }
                    }
                }

                if (estaProcesando) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(Color.Black.copy(alpha = 0.6f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            CircularProgressIndicator(color = Color(0xFF2563EB))
                            Spacer(modifier = Modifier.height(10.dp))
                            Text("Ejecutando MobileNetV2...", color = Color.White, fontSize = 12.sp)
                        }
                    }
                }
            }
        }

        // --- 3. ACCIONES Y VISUALIZACIÓN DE RESULTADOS (HU-04 / SP-03) ---
        Column(modifier = Modifier.fillMaxWidth()) {

            // Botón de Clasificación Automática
            Button(
                onClick = {
                    coroutineScope.launch {
                        estaProcesando = true
                        delay(1500) // Simulación del tiempo de carga/redimensión
                        estaProcesando = false
                        resultadoTipo = clasesCatarata.random()
                        confianza = Random.nextInt(84, 97)
                        tiempoInferencia = Random.nextInt(110, 185) // Simula la métrica RN-001 (< 200ms)
                    }
                },
                enabled = imageUri != null && !estaProcesando,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF2563EB),
                    disabledContainerColor = Color(0xFF9CA3AF)
                )
            ) {
                Text("Clasificar Imagen", fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Panel Informativo de Resultados (HU-04 y SP-03)
            AnimatedVisibility(visible = resultadoTipo != null) {
                resultadoTipo?.let { tipo ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        border = BorderStroke(1.dp, Color(0xFFE5E7EB))
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF10B981))
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "ANÁLISIS COMPLETADO",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF10B981)
                                )
                            }
                            Spacer(modifier = Modifier.height(12.dp))

                            // HU-04: Tipología
                            Text(
                                text = "Tipo Detectado: $tipo",
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF1F2937)
                            )

                            Spacer(modifier = Modifier.height(8.dp))

                            // HU-04: Porcentaje de confianza
                            Text(
                                text = "Nivel de confianza: $confianza%",
                                fontSize = 14.sp,
                                color = Color(0xFF4B5563)
                            )
                            LinearProgressIndicator(
                                progress = { confianza / 100f },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 6.dp)
                                    .height(6.dp)
                                    .clip(RoundedCornerShape(3.dp)),
                                color = Color(0xFF2563EB),
                                trackColor = Color(0xFFE5E7EB),
                            )

                            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp), color = Color(0xFFF3F4F6))

                            // SP-03 y RN-001: Métrica de Profiling integrada
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(text = "Latencia de inferencia:", fontSize = 12.sp, color = Color(0xFF6B7280))
                                Text(
                                    text = "$tiempoInferencia ms (< 200ms)",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (tiempoInferencia < 200) Color(0xFF10B981) else Color.Red
                                )
                            }
                        }
                    }
                }
            }

            if (imageUri != null && !estaProcesando) {
                TextButton(
                    onClick = {
                        imageUri = null
                        resultadoTipo = null
                    },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Remover muestra actual", color = Color(0xFFEF4444))
                }
            } else {
                Spacer(modifier = Modifier.height(48.dp))
            }
        }
    }
}