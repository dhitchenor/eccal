package com.dhitchenor.eccal

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter

/**
 * Storage Access Framework (SAF) handler for EchoDAV
 * Handles all SAF operations including directory picking, file reading/writing
 */
class SafHandler(private val activity: FlutterActivity) {
    companion object {
        const val CHANNEL_NAME = "com.dhitchenor.eccal/saf"
        const val REQUEST_CODE_OPEN_DOCUMENT_TREE = 42
    }

    private var pendingResult: MethodChannel.Result? = null

    /**
     * Set up the method channel for SAF operations
     */
    fun setupMethodChannel(channel: MethodChannel) {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "pickDirectory" -> {
                    pickDirectory(result)
                }

                "persistUriPermission" -> {
                    val uriString = call.argument<String>("uri")
                    persistUriPermission(uriString, result)
                }

                "writeFile" -> {
                    val uriString = call.argument<String>("treeUri")
                    val fileName = call.argument<String>("fileName")
                    val content = call.argument<String>("content")
                    val subfolder = call.argument<String>("subfolder") // Optional
                    writeFile(uriString, fileName, content, subfolder, result)
                }

                "writeFileBytes" -> {
                    val uriString = call.argument<String>("treeUri")
                    val fileName = call.argument<String>("fileName")
                    val bytes = call.argument<ByteArray>("bytes")
                    val subfolder = call.argument<String>("subfolder") // Optional
                    writeFileBytes(uriString, fileName, bytes, subfolder, result)
                }

                "readFile" -> {
                    val uriString = call.argument<String>("treeUri")
                    val fileName = call.argument<String>("fileName")
                    val subfolder = call.argument<String>("subfolder") // Optional
                    readFile(uriString, fileName, subfolder, result)
                }

                "listFiles" -> {
                    val uriString = call.argument<String>("treeUri")
                    val subfolder = call.argument<String>("subfolder") // Optional
                    listFiles(uriString, subfolder, result)
                }

                "deleteFile" -> {
                    val uriString = call.argument<String>("treeUri")
                    val fileName = call.argument<String>("fileName")
                    val subfolder = call.argument<String>("subfolder") // Optional
                    deleteFile(uriString, fileName, subfolder, result)
                }

                "checkAccess" -> {
                    val uriString = call.argument<String>("uri")
                    checkAccess(uriString, result)
                }

                "getDisplayName" -> {
                    val uriString = call.argument<String>("treeUri")
                    getDisplayName(uriString, result)
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Open the system document tree picker
     */
    private fun pickDirectory(result: MethodChannel.Result) {
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
        }
        activity.startActivityForResult(intent, REQUEST_CODE_OPEN_DOCUMENT_TREE)
    }

    /**
     * Handle the result from the document tree picker
     * Call this from your MainActivity's onActivityResult
     */
    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_CODE_OPEN_DOCUMENT_TREE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val treeUri = data.data
                if (treeUri != null) {
                    // Take persistable permissions
                    try {
                        activity.contentResolver.takePersistableUriPermission(
                            treeUri,
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                        )
                        pendingResult?.success(treeUri.toString())
                    } catch (e: Exception) {
                        pendingResult?.error("PERMISSION_ERROR", "Failed to persist permissions: ${e.message}", null)
                    }
                } else {
                    pendingResult?.error("NULL_URI", "Received null URI", null)
                }
            } else {
                pendingResult?.error("CANCELLED", "User cancelled directory selection", null)
            }
            pendingResult = null
        }
    }

    /**
     * Persist URI permissions (called when restoring from saved URI)
     */
    private fun persistUriPermission(uriString: String?, result: MethodChannel.Result) {
        if (uriString == null) {
            result.error("NULL_URI", "URI string is null", null)
            return
        }

        try {
            val uri = Uri.parse(uriString)
            activity.contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
            result.success(true)
        } catch (e: Exception) {
            result.error("PERMISSION_ERROR", "Failed to persist permission: ${e.message}", null)
        }
    }

    /**
     * Write content to a file in the SAF directory (with optional subfolder)
     */
    private fun writeFile(
        treeUriString: String?,
        fileName: String?,
        content: String?,
        subfolder: String?,
        result: MethodChannel.Result
    ) {
        if (treeUriString == null || fileName == null || content == null) {
            result.error("INVALID_ARGS", "Missing required arguments", null)
            return
        }

        try {
            val treeUri = Uri.parse(treeUriString)
            val documentUri = DocumentsContract.buildDocumentUriUsingTree(
                treeUri,
                DocumentsContract.getTreeDocumentId(treeUri)
            )

            var directory = DocumentFile.fromTreeUri(activity, treeUri)
            if (directory == null || !directory.canWrite()) {
                result.error("NO_WRITE_ACCESS", "Cannot write to directory", null)
                return
            }

            // Navigate to subfolder if specified
            if (subfolder != null && subfolder.isNotEmpty()) {
                var subDir = directory.findFile(subfolder)
                if (subDir == null || !subDir.isDirectory) {
                    // Create subfolder if it doesn't exist
                    subDir = directory.createDirectory(subfolder)
                    if (subDir == null) {
                        result.error("CREATE_SUBFOLDER_FAILED", "Failed to create subfolder: $subfolder", null)
                        return
                    }
                }
                directory = subDir
            }

            // Check if file exists, delete it if it does
            var file = directory.findFile(fileName)
            if (file != null) {
                file.delete()
            }

            // Determine MIME type based on file extension
            val mimeType = when {
                fileName.endsWith(".ics", ignoreCase = true) -> "text/calendar"
                fileName.endsWith(".txt", ignoreCase = true) -> "text/plain"
                fileName.endsWith(".md", ignoreCase = true) -> "text/markdown"
                else -> "text/plain"
            }

            // Create new file with appropriate MIME type
            file = directory.createFile(mimeType, fileName)
            if (file == null) {
                result.error("CREATE_FAILED", "Failed to create file", null)
                return
            }

            // Write content
            activity.contentResolver.openOutputStream(file.uri)?.use { outputStream ->
                OutputStreamWriter(outputStream).use { writer ->
                    writer.write(content)
                    writer.flush()
                }
            }

            result.success(file.uri.toString())
        } catch (e: Exception) {
            result.error("WRITE_ERROR", "Failed to write file: ${e.message}", null)
        }
    }

    /**
     * Write binary content to a file in the SAF directory (with optional subfolder)
     */
    private fun writeFileBytes(
        treeUriString: String?,
        fileName: String?,
        bytes: ByteArray?,
        subfolder: String?,
        result: MethodChannel.Result
    ) {
        if (treeUriString == null || fileName == null || bytes == null) {
            result.error("INVALID_ARGS", "Missing required arguments", null)
            return
        }

        try {
            val treeUri = Uri.parse(treeUriString)
            val documentUri = DocumentsContract.buildDocumentUriUsingTree(
                treeUri,
                DocumentsContract.getTreeDocumentId(treeUri)
            )

            var directory = DocumentFile.fromTreeUri(activity, treeUri)
            if (directory == null || !directory.canWrite()) {
                result.error("NO_WRITE_ACCESS", "Cannot write to directory", null)
                return
            }

            // Navigate to subfolder if specified
            if (subfolder != null && subfolder.isNotEmpty()) {
                var subDir = directory.findFile(subfolder)
                if (subDir == null || !subDir.isDirectory) {
                    // Create subfolder if it doesn't exist
                    subDir = directory.createDirectory(subfolder)
                    if (subDir == null) {
                        result.error("CREATE_SUBFOLDER_FAILED", "Failed to create subfolder: $subfolder", null)
                        return
                    }
                }
                directory = subDir
            }

            // Check if file exists, delete it if it does
            var file = directory.findFile(fileName)
            if (file != null) {
                file.delete()
            }

            // Determine MIME type based on file extension
            val mimeType = when {
                fileName.endsWith(".zip", ignoreCase = true) -> "application/zip"
                fileName.endsWith(".pdf", ignoreCase = true) -> "application/pdf"
                fileName.endsWith(".jpg", ignoreCase = true) || fileName.endsWith(
                    ".jpeg",
                    ignoreCase = true
                ) -> "image/jpeg"

                fileName.endsWith(".png", ignoreCase = true) -> "image/png"
                else -> "application/octet-stream"
            }

            // Create new file with appropriate MIME type
            file = directory.createFile(mimeType, fileName)
            if (file == null) {
                result.error("CREATE_FAILED", "Failed to create file", null)
                return
            }

            // Write binary content
            activity.contentResolver.openOutputStream(file.uri)?.use { outputStream ->
                outputStream.write(bytes)
                outputStream.flush()
            }

            result.success(file.uri.toString())
        } catch (e: Exception) {
            result.error("WRITE_ERROR", "Failed to write file: ${e.message}", null)
        }
    }

    /**
     * Read content from a file in the SAF directory
     */
    /**
     * Read content from a file in the SAF directory (with optional subfolder)
     */
    private fun readFile(
        treeUriString: String?,
        fileName: String?,
        subfolder: String?,
        result: MethodChannel.Result
    ) {
        if (treeUriString == null || fileName == null) {
            result.error("INVALID_ARGS", "Missing required arguments", null)
            return
        }

        try {
            val treeUri = Uri.parse(treeUriString)
            var directory = DocumentFile.fromTreeUri(activity, treeUri)

            if (directory == null || !directory.canRead()) {
                result.error("NO_READ_ACCESS", "Cannot read from directory", null)
                return
            }

            // Navigate to subfolder if specified
            if (subfolder != null && subfolder.isNotEmpty()) {
                val subDir = directory.findFile(subfolder)
                if (subDir == null || !subDir.isDirectory) {
                    result.error("SUBFOLDER_NOT_FOUND", "Subfolder not found: $subfolder", null)
                    return
                }
                directory = subDir
            }

            val file = directory.findFile(fileName)
            if (file == null || !file.exists()) {
                result.error("FILE_NOT_FOUND", "File not found: $fileName", null)
                return
            }

            // Read content
            val content = StringBuilder()
            activity.contentResolver.openInputStream(file.uri)?.use { inputStream ->
                BufferedReader(InputStreamReader(inputStream)).use { reader ->
                    var line: String?
                    while (reader.readLine().also { line = it } != null) {
                        content.append(line).append("\n")
                    }
                }
            }

            result.success(content.toString())
        } catch (e: Exception) {
            result.error("READ_ERROR", "Failed to read file: ${e.message}", null)
        }
    }

    /**
     * List all files in the SAF directory
     */
    private fun listFiles(
        treeUriString: String?,
        subfolder: String?,
        result: MethodChannel.Result
    ) {
        if (treeUriString == null) {
            result.error("INVALID_ARGS", "Tree URI is null", null)
            return
        }

        try {
            val treeUri = Uri.parse(treeUriString)
            var directory = DocumentFile.fromTreeUri(activity, treeUri)

            if (directory == null || !directory.canRead()) {
                result.error("NO_READ_ACCESS", "Cannot read from directory", null)
                return
            }

            // Navigate to subfolder if specified
            if (subfolder != null && subfolder.isNotEmpty()) {
                val subDir = directory.findFile(subfolder)
                if (subDir == null || !subDir.isDirectory) {
                    // Subfolder doesn't exist yet, return empty list
                    result.success(emptyList<String>())
                    return
                }
                directory = subDir
            }

            val fileNames = directory.listFiles()
                .filter { it.isFile && it.name?.endsWith(".ics") == true }
                .mapNotNull { it.name }

            result.success(fileNames)
        } catch (e: Exception) {
            result.error("LIST_ERROR", "Failed to list files: ${e.message}", null)
        }
    }

    /**
     * Delete a file from the SAF directory
     */
    /**
     * Delete a file from the SAF directory (with optional subfolder)
     */
    private fun deleteFile(
        treeUriString: String?,
        fileName: String?,
        subfolder: String?,
        result: MethodChannel.Result
    ) {
        if (treeUriString == null || fileName == null) {
            result.error("INVALID_ARGS", "Missing required arguments", null)
            return
        }

        try {
            val treeUri = Uri.parse(treeUriString)
            var directory = DocumentFile.fromTreeUri(activity, treeUri)

            if (directory == null || !directory.canWrite()) {
                result.error("NO_WRITE_ACCESS", "Cannot write to directory", null)
                return
            }

            // Navigate to subfolder if specified
            if (subfolder != null && subfolder.isNotEmpty()) {
                val subDir = directory.findFile(subfolder)
                if (subDir == null || !subDir.isDirectory) {
                    result.error("SUBFOLDER_NOT_FOUND", "Subfolder not found: $subfolder", null)
                    return
                }
                directory = subDir
            }

            val file = directory.findFile(fileName)
            if (file == null) {
                result.error("FILE_NOT_FOUND", "File not found: $fileName", null)
                return
            }

            val deleted = file.delete()
            result.success(deleted)
        } catch (e: Exception) {
            result.error("DELETE_ERROR", "Failed to delete file: ${e.message}", null)
        }
    }

    /**
     * Check if we have access to a saved URI
     */
    private fun checkAccess(uriString: String?, result: MethodChannel.Result) {
        if (uriString == null) {
            result.success(false)
            return
        }

        try {
            val uri = Uri.parse(uriString)
            val directory = DocumentFile.fromTreeUri(activity, uri)
            result.success(directory != null && directory.canRead() && directory.canWrite())
        } catch (e: Exception) {
            result.success(false)
        }
    }

    /**
     * Get the display name (folder name) for a tree URI
     */
    private fun getDisplayName(treeUriString: String?, result: MethodChannel.Result) {
        if (treeUriString == null) {
            result.success(null)
            return
        }

        try {
            val treeUri = Uri.parse(treeUriString)
            val directory = DocumentFile.fromTreeUri(activity, treeUri)

            if (directory != null) {
                result.success(directory.name)
            } else {
                result.success(null)
            }
        } catch (e: Exception) {
            result.success(null)
        }
    }
}
