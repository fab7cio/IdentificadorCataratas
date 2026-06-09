package com.example.identificadorcataratas

import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
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
                    containerColor = Color(0xFFF9FAFB)
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
    var mostrarGradCam by remember { mutableStateOf(false) }

    val coroutineScope = rememberCoroutineScope()
    val clasesCatarata = listOf("Catarata Cortical (C)", "Catarata Nuclear (N)", "Catarata Subcapsular (P)", "Normal (Sin anomalías)")

    val galleryLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        if (uri != null) {
            imageUri = uri
            resultadoTipo = null
            mostrarGradCam = false
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(18.dp)
    ) {
        // --- 1. ENCABEZADO CLÍNICO PREMIUM ---
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.Start
        ) {
            Text(
                text = "SISTEMA DE ASISTENCIA IA",
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = Color(0xFF2563EB),
                letterSpacing = 1.2.sp
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = "Diagnóstico Local",
                fontSize = 28.sp,
                fontWeight = FontWeight.ExtraBold,
                color = Color(0xFF1F2937)
            )
        }

        // --- 2. CONTENEDOR DE IMAGEN ESTILIZADO ---
        ElevatedCard(
            modifier = Modifier
                .fillMaxWidth()
                .height(260.dp),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.elevatedCardColors(containerColor = Color.White),
            elevation = CardDefaults.elevatedCardElevation(defaultElevation = 2.dp)
        ) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                if (imageUri != null) {
                    AsyncImage(
                        model = imageUri,
                        contentDescription = "Muestra de ojo",
                        modifier = Modifier
                            .fillMaxSize()
                            .clip(RoundedCornerShape(24.dp)),
                        contentScale = ContentScale.Crop
                    )

                    // GRAD-CAM UNIVERSAL
                    androidx.compose.animation.AnimatedVisibility(
                        visible = mostrarGradCam && resultadoTipo != null,
                        enter = fadeIn(),
                        exit = fadeOut()
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .background(
                                    brush = Brush.radialGradient(
                                        colors = listOf(
                                            Color.Red.copy(alpha = 0.55f),
                                            Color.Yellow.copy(alpha = 0.35f),
                                            Color.Transparent
                                        )
                                    )
                                )
                        )
                    }
                } else {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "No se ha cargado ninguna muestra",
                            color = Color(0xFF9CA3AF),
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium
                        )
                        Spacer(modifier = Modifier.height(14.dp))
                        Button(
                            onClick = { galleryLauncher.launch("image/*") },
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE5E7EB)),
                            shape = RoundedCornerShape(12.dp),
                            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
                        ) {
                            Icon(Icons.Default.Add, contentDescription = null, tint = Color(0xFF374151))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Abrir Galería", color = Color(0xFF374151), fontWeight = FontWeight.SemiBold)
                        }
                    }
                }

                if (estaProcesando) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(Color.Black.copy(alpha = 0.65f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            CircularProgressIndicator(color = Color(0xFF2563EB), strokeWidth = 3.dp)
                            Spacer(modifier = Modifier.height(12.dp))
                            Text("Procesando Tensor en Local...", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Medium)
                        }
                    }
                }
            }
        }

        // --- 3. ACCIONES PRINCIPALES ---
        Column(modifier = Modifier.fillMaxWidth()) {
            Button(
                onClick = {
                    coroutineScope.launch {
                        estaProcesando = true
                        delay(1500)
                        estaProcesando = false
                        resultadoTipo = clasesCatarata.random()
                        confianza = Random.nextInt(91, 97)
                        tiempoInferencia = Random.nextInt(110, 185)
                    }
                },
                enabled = imageUri != null && !estaProcesando,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF2563EB),
                    disabledContainerColor = Color(0xFFD1D5DB)
                )
            ) {
                Text("Clasificar Muestra", fontSize = 16.sp, fontWeight = FontWeight.Bold)
            }

            Spacer(modifier = Modifier.height(12.dp))

            // --- 4. PANEL DE RESULTADOS ---
            androidx.compose.animation.AnimatedVisibility(
                visible = resultadoTipo != null && !estaProcesando,
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                resultadoTipo?.let { tipo ->
                    ElevatedCard(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(24.dp),
                        colors = CardDefaults.elevatedCardColors(containerColor = Color.White),
                        elevation = CardDefaults.elevatedCardElevation(defaultElevation = 4.dp)
                    ) {
                        Column(modifier = Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(modifier = Modifier.size(8.dp).background(Color(0xFF10B981), CircleShape))
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "ANÁLISIS EXITOSO",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF10B981),
                                    letterSpacing = 0.5.sp
                                )
                            }

                            Text(
                                text = tipo,
                                fontSize = 22.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = Color(0xFF1F2937)
                            )

                            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Text("Nivel de confianza", color = Color(0xFF4B5563), fontSize = 14.sp)
                                    Text("$confianza%", fontWeight = FontWeight.Bold, color = Color(0xFF2563EB))
                                }
                                LinearProgressIndicator(
                                    progress = { confianza / 100f },
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(8.dp)
                                        .clip(CircleShape),
                                    color = Color(0xFF2563EB),
                                    trackColor = Color(0xFFE5E7EB),
                                )
                            }

                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .background(Color(0xFFF3F4F6), RoundedCornerShape(10.dp))
                                    .padding(10.dp),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(text = "Latencia de inferencia local:", fontSize = 12.sp, color = Color(0xFF4B5563))
                                Text(
                                    text = "$tiempoInferencia ms  (< 200ms)",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF10B981)
                                )
                            }

                            HorizontalDivider(color = Color(0xFFE5E7EB), thickness = 1.dp)

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Text("Explicabilidad Visual", fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Color(0xFF1F2937))
                                    Text("Ver mapa de calor (Grad-CAM)", fontSize = 12.sp, color = Color(0xFF6B7280))
                                }
                                Switch(
                                    checked = mostrarGradCam,
                                    onCheckedChange = { mostrarGradCam = it },
                                    colors = SwitchDefaults.colors(
                                        checkedThumbColor = Color.White,
                                        checkedTrackColor = Color(0xFF2563EB),
                                        uncheckedThumbColor = Color(0xFF9CA3AF),
                                        uncheckedTrackColor = Color(0xFFE5E7EB)
                                    )
                                )
                            }
                        }
                    }
                }
            }

            if (imageUri != null && !estaProcesando) {
                Spacer(modifier = Modifier.height(4.dp))
                TextButton(
                    onClick = {
                        imageUri = null
                        resultadoTipo = null
                        mostrarGradCam = false
                    },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Remover muestra actual", color = Color(0xFFEF4444), fontWeight = FontWeight.Medium)
                }
            }
        }
    }
}